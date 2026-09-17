import 'dart:convert';
import 'dart:typed_data';
import 'package:shonenx/core/services/backup_service.dart';
import 'package:shonenx/features/sync/crypto/sync_cipher.dart';
import 'package:shonenx/features/sync/crypto/sync_identity.dart';
import 'package:shonenx/features/sync/domain/models/sync_snapshot.dart';

/// Bridges the local application database and preferences with the encrypted P2P sync system.
class SyncDataBridge {
  final BackupService _backupService;

  SyncDataBridge(this._backupService);

  Future<Map<BackupCategory, int>> getExistingCounts() =>
      _backupService.getExistingCounts();

  /// Captures the complete local state, packages it into a signed [SyncSnapshot],
  /// and produces an authenticated encrypted byte payload ready for seeding.
  Future<({SyncSnapshot snapshot, Uint8List encryptedPayload})> captureAndEncrypt({
    required SyncIdentity identity,
    required int version,
  }) async {
    final manifest = await _backupService.exportData(BackupCategory.values.toSet());
    final timestamp = DateTime.now();

    // Construct preliminary snapshot for signing
    final unsignedSnapshot = SyncSnapshot(
      peerId: identity.peerId,
      version: version,
      timestamp: timestamp,
      data: manifest.data,
      signature: '',
    );

    // Sign the canonical bytes with the user's Ed25519 key
    final signableBytes = unsignedSnapshot.toSignableBytes();
    final signatureBytes = await SyncCipher.sign(signableBytes, identity.signingKeyPair);
    final signatureBase64 = base64Encode(signatureBytes);

    final signedSnapshot = unsignedSnapshot.copyWith(signature: signatureBase64);

    // Encrypt the signed snapshot with the user's AES-GCM secret key
    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(signedSnapshot.toJson())));
    final encryptedPayload = await SyncCipher.encrypt(plaintext, identity.encryptionKey);

    return (snapshot: signedSnapshot, encryptedPayload: encryptedPayload);
  }

  /// Decrypts an encrypted payload, verifies the digital signature, and restores
  /// all data into local storage (Isar & SharedPreferences).
  Future<SyncSnapshot> decryptAndApply({
    required Uint8List encryptedPayload,
    required SyncIdentity identity,
  }) async {
    // Decrypt payload
    final decryptedBytes = await SyncCipher.decrypt(
      encryptedPayload,
      identity.encryptionKey,
    );

    final jsonMap = jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;
    final snapshot = SyncSnapshot.fromJson(jsonMap);

    // Verify digital signature
    final signatureBytes = base64Decode(snapshot.signature);
    final signableBytes = snapshot.toSignableBytes();
    final isValid = await SyncCipher.verify(
      data: signableBytes,
      signatureBytes: signatureBytes,
      publicKeyBytes: identity.publicKeyBytes,
    );

    if (!isValid) {
      throw StateError('Signature verification failed: Snapshot was altered or forged.');
    }

    // Convert to BackupManifest and import into local storage
    final manifest = BackupManifest(
      appVersion: '2.0.0',
      exportDate: snapshot.timestamp,
      categories: BackupCategory.values.toSet(),
      data: snapshot.data,
    );

    await _backupService.importData(manifest, BackupCategory.values.toSet());

    return snapshot;
  }
}
