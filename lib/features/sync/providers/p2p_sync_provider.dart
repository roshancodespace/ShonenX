import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/backup_provider.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/sync/crypto/sync_identity.dart';
import 'package:shonenx/features/sync/domain/models/seeder_blob.dart';
import 'package:shonenx/features/sync/network/p2p_channel.dart';
import 'package:shonenx/features/sync/network/seeder_storage_manager.dart';
import 'package:shonenx/features/sync/network/swarm_peer_discovery.dart';
import 'package:shonenx/features/sync/services/sync_data_bridge.dart';

class P2PSyncState {
  final SyncIdentity? identity;
  final bool isInitialized;
  final bool isSyncing;
  final int activePeersCount;
  final int seededPeersCount;
  final int seederDataSizeBytes;
  final DateTime? lastSyncDate;
  final String? syncError;
  final int snapshotVersion;

  const P2PSyncState({
    this.identity,
    this.isInitialized = false,
    this.isSyncing = false,
    this.activePeersCount = 0,
    this.seededPeersCount = 0,
    this.seederDataSizeBytes = 0,
    this.lastSyncDate,
    this.syncError,
    this.snapshotVersion = 1,
  });

  bool get isSignedIn => identity != null;

  P2PSyncState copyWith({
    SyncIdentity? identity,
    bool? isInitialized,
    bool? isSyncing,
    int? activePeersCount,
    int? seededPeersCount,
    int? seederDataSizeBytes,
    DateTime? lastSyncDate,
    String? syncError,
    int? snapshotVersion,
    bool clearIdentity = false,
  }) {
    return P2PSyncState(
      identity: clearIdentity ? null : (identity ?? this.identity),
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
      activePeersCount: activePeersCount ?? this.activePeersCount,
      seededPeersCount: seededPeersCount ?? this.seededPeersCount,
      seederDataSizeBytes: seederDataSizeBytes ?? this.seederDataSizeBytes,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      syncError: syncError,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
    );
  }
}

final seederStorageManagerProvider = Provider<SeederStorageManager>((ref) {
  return SeederStorageManager();
});

final syncDataBridgeProvider = Provider<SyncDataBridge>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return SyncDataBridge(backupService);
});

final p2pSyncProvider =
    NotifierProvider<P2PSyncNotifier, P2PSyncState>(P2PSyncNotifier.new);

class P2PSyncNotifier extends Notifier<P2PSyncState> {
  late final SharedPreferences _prefs;
  late final SeederStorageManager _storageManager;
  late final SyncDataBridge _dataBridge;

  P2PChannel? _p2pChannel;
  SwarmPeerDiscovery? _discovery;
  Timer? _dailySyncTimer;

  static const _prefLastSync = 'kurox_p2p_last_sync_timestamp';
  static const _prefVersion = 'kurox_p2p_snapshot_version';

  @override
  P2PSyncState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _storageManager = SeederStorageManager();
    _dataBridge = ref.watch(syncDataBridgeProvider);

    ref.onDispose(() {
      _stopP2PNetwork();
    });

    _initialize();
    return const P2PSyncState();
  }

  Future<void> _initialize() async {
    try {
      final identity = await SyncIdentity.loadFromStorage();
      final lastSyncMs = _prefs.getInt(_prefLastSync);
      final lastSync = lastSyncMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs) : null;
      final version = _prefs.getInt(_prefVersion) ?? 1;

      final seederSize = await _storageManager.getTotalSizeBytes();
      final seededCount = await _storageManager.getSeededPeersCount();

      state = state.copyWith(
        identity: identity,
        isInitialized: true,
        lastSyncDate: lastSync,
        snapshotVersion: version,
        seederDataSizeBytes: seederSize,
        seededPeersCount: seededCount,
      );

      if (identity != null) {
        await _startP2PNetwork(identity);
        _checkDailySyncSchedule();
      }
    } catch (e) {
      state = state.copyWith(isInitialized: true, syncError: e.toString());
    }
  }

  /// Determines whether an incoming blob should be accepted and restored.
  /// Relaxed backwards-compatibility allows backups from older app versions,
  /// lower sequential counters with newer timestamps, or uninitialized devices.
  bool _shouldAcceptIncomingBlob(SeederBlob blob, SyncIdentity identity) {
    if (blob.targetPeerId != identity.peerId) return false;

    // 1. Strictly higher version counter -> always apply
    if (blob.version > state.snapshotVersion) return true;

    // 2. Uninitialized / restored device that hasn't synced yet -> always apply
    final lastSync = state.lastSyncDate;
    if (lastSync == null) return true;

    // 3. Newer timestamp than last successful sync (e.g. from an older version of client)
    if (blob.timestamp.isAfter(lastSync)) return true;

    // 4. Equal version counter with reasonable interval since last sync
    if (blob.version >= state.snapshotVersion &&
        DateTime.now().difference(lastSync).inSeconds >= 10) {
      return true;
    }

    return false;
  }

  /// Starts the P2P networking channel and LAN discovery.
  Future<void> _startP2PNetwork(SyncIdentity identity) async {
    await _stopP2PNetwork();

    _p2pChannel = P2PChannel(
      localPeerId: identity.peerId,
      storageManager: _storageManager,
      onBlobReceived: (blob) async {
        await _refreshSeederStats();
        // If this blob belongs to us, verify if it should be accepted & applied
        if (_shouldAcceptIncomingBlob(blob, identity)) {
          try {
            await _dataBridge.decryptAndApply(
              encryptedPayload: blob.payloadBytes,
              identity: identity,
            );
            final newVersion = math.max(blob.version, state.snapshotVersion);
            await _saveSyncSuccess(newVersion, timestamp: blob.timestamp);
          } catch (_) {}
        }
      },
      onPeerDiscovered: (peerId, ip, port) {
        state = state.copyWith(
          activePeersCount: _p2pChannel?.activeConnectionsCount ?? 0,
        );
      },
    );

    final tcpPort = await _p2pChannel!.startServer();

    _discovery = SwarmPeerDiscovery(
      localPeerId: identity.peerId,
      localTcpPort: tcpPort,
      onPeerFound: (peerId, host, port) async {
        await _p2pChannel?.connectToPeer(host, port);
        state = state.copyWith(
          activePeersCount: _p2pChannel?.activeConnectionsCount ?? 0,
        );
      },
    );

    await _discovery!.start();

    // Schedule daily sync checker (runs every 1 hour to check if 24h elapsed)
    _dailySyncTimer?.cancel();
    _dailySyncTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkDailySyncSchedule();
    });
  }

  Future<void> _stopP2PNetwork() async {
    _dailySyncTimer?.cancel();
    _dailySyncTimer = null;
    await _discovery?.stop();
    _discovery = null;
    await _p2pChannel?.stop();
    _p2pChannel = null;
  }

  void _checkDailySyncSchedule() {
    final lastSync = state.lastSyncDate;
    if (lastSync == null || DateTime.now().difference(lastSync).inHours >= 24) {
      syncNow();
    }
  }

  /// Signs up: Generates a new identity, persists it, and begins seeding immediately.
  /// Returns the 12-word mnemonic recovery phrase.
  Future<String> signUp() async {
    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      final identity = await SyncIdentity.generateAndSave();
      state = state.copyWith(identity: identity, isSyncing: false);

      await _startP2PNetwork(identity);
      await syncNow();

      return identity.mnemonic;
    } catch (e) {
      state = state.copyWith(isSyncing: false, syncError: e.toString());
      rethrow;
    }
  }

  /// Signs in: Restores identity from a 12-word recovery mnemonic and restores data.
  Future<void> signInWithMnemonic(String mnemonic) async {
    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      final identity = await SyncIdentity.fromMnemonic(mnemonic);
      await identity.saveToStorage();

      // Clear previous local version counter so any incoming backup is accepted
      await _prefs.remove(_prefVersion);
      await _prefs.remove(_prefLastSync);

      state = state.copyWith(
        identity: identity,
        snapshotVersion: 0,
        lastSyncDate: null,
      );
      await _startP2PNetwork(identity);

      // Immediately query peers for our backup blob
      _p2pChannel?.requestBlob(identity.peerId);

      // Only seed current state if this device already had existing database items
      final counts = await _dataBridge.getExistingCounts();
      final totalLocalItems = counts.values.fold(0, (a, b) => a + b);
      if (totalLocalItems > 0) {
        await syncNow();
      } else {
        state = state.copyWith(isSyncing: false);
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false, syncError: e.toString());
      rethrow;
    }
  }

  /// Synchronizes current state: captures local DB, encrypts, and broadcasts to peers.
  Future<void> syncNow() async {
    final identity = state.identity;
    if (identity == null) return;

    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      final nextVersion = state.snapshotVersion + 1;
      final result = await _dataBridge.captureAndEncrypt(
        identity: identity,
        version: nextVersion,
      );

      final myBlob = SeederBlob.fromPayload(
        targetPeerId: identity.peerId,
        version: nextVersion,
        timestamp: result.snapshot.timestamp,
        signature: result.snapshot.signature,
        encryptedBytes: result.encryptedPayload,
      );

      // Save to local cache
      await _storageManager.saveBlob(myBlob);

      // Broadcast seed offer to all connected peers
      _p2pChannel?.broadcastSeedOffer(myBlob);

      // Also request if any peers have a newer blob for us
      _p2pChannel?.requestBlob(identity.peerId);

      await _saveSyncSuccess(nextVersion);
      await _refreshSeederStats();
    } catch (e) {
      state = state.copyWith(isSyncing: false, syncError: e.toString());
    }
  }

  /// Clears all cached peer data hosted on this device ("Delete Seeder Data").
  Future<void> clearSeederData() async {
    await _storageManager.clearAllSeederData();
    await _refreshSeederStats();
  }

  Future<void> _refreshSeederStats() async {
    final size = await _storageManager.getTotalSizeBytes();
    final count = await _storageManager.getSeededPeersCount();
    state = state.copyWith(
      seederDataSizeBytes: size,
      seededPeersCount: count,
      activePeersCount: _p2pChannel?.activeConnectionsCount ?? 0,
    );
  }

  Future<void> _saveSyncSuccess(int version, {DateTime? timestamp}) async {
    final now = timestamp ?? DateTime.now();
    await _prefs.setInt(_prefLastSync, now.millisecondsSinceEpoch);
    await _prefs.setInt(_prefVersion, version);

    state = state.copyWith(
      isSyncing: false,
      lastSyncDate: now,
      snapshotVersion: version,
      syncError: null,
    );
  }

  /// Signs out and deletes identity from secure storage.
  Future<void> signOut() async {
    await _stopP2PNetwork();
    await SyncIdentity.clearStorage();
    state = state.copyWith(clearIdentity: true, activePeersCount: 0);
  }
}
