import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/features/sync/domain/models/seeder_blob.dart';

/// Manages the local on-disk storage of opaque, encrypted peer blobs ("Seeder Data").
/// Provides methods to inspect storage usage and delete cached peer blobs on demand.
class SeederStorageManager {
  static const int defaultMaxCacheBytes = 50 * 1024 * 1024; // 50 MB default cap

  Future<Directory> _getSeederDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/kurox_seeder_data');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _getBlobFile(Directory dir, String peerId) {
    return File('${dir.path}/peer_$peerId.blob');
  }

  /// Saves or updates a cached peer blob.
  /// Automatically purges oldest blobs if cache exceeds [maxCacheBytes].
  Future<void> saveBlob(SeederBlob blob, {int maxCacheBytes = defaultMaxCacheBytes}) async {
    try {
      final dir = await _getSeederDirectory();
      final file = _getBlobFile(dir, blob.targetPeerId);

      // Protect against older versions overwriting newer cached snapshots
      if (await file.exists()) {
        try {
          final existingStr = await file.readAsString();
          final existingJson = jsonDecode(existingStr) as Map<String, dynamic>;
          final existing = SeederBlob.fromJson(existingJson);
          if (existing.version > blob.version && existing.timestamp.isAfter(blob.timestamp)) {
            return;
          }
        } catch (_) {}
      }

      final jsonStr = jsonEncode(blob.toJson());
      await file.writeAsString(jsonStr, flush: true);

      // Enforce storage quota
      await _enforceStorageQuota(dir, maxCacheBytes);
    } catch (_) {
      // Storage operations should fail gracefully without disrupting playback/app UI
    }
  }

  /// Retrieves a cached blob by target peer ID, or null if not held locally.
  Future<SeederBlob?> getBlob(String peerId) async {
    try {
      final dir = await _getSeederDirectory();
      final file = _getBlobFile(dir, peerId);
      if (!await file.exists()) return null;

      final jsonStr = await file.readAsString();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SeederBlob.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Returns all cached peer blobs currently held on this device.
  Future<List<SeederBlob>> getAllBlobs() async {
    final blobs = <SeederBlob>[];
    try {
      final dir = await _getSeederDirectory();
      final entities = await dir.list().toList();

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.blob')) {
          try {
            final jsonStr = await entity.readAsString();
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            blobs.add(SeederBlob.fromJson(map));
          } catch (_) {}
        }
      }
    } catch (_) {}
    return blobs;
  }

  /// Calculates the total disk space in bytes consumed by cached peer blobs.
  Future<int> getTotalSizeBytes() async {
    try {
      final dir = await _getSeederDirectory();
      final entities = await dir.list().toList();
      int total = 0;
      for (final entity in entities) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Returns the number of distinct peers currently hosted/seeded by this device.
  Future<int> getSeededPeersCount() async {
    try {
      final dir = await _getSeederDirectory();
      final entities = await dir.list().toList();
      return entities.whereType<File>().where((f) => f.path.endsWith('.blob')).length;
    } catch (_) {
      return 0;
    }
  }

  /// Completely purges all cached peer blobs ("Delete Seeder Data" in settings).
  Future<void> clearAllSeederData() async {
    try {
      final dir = await _getSeederDirectory();
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        for (final entity in entities) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }

  /// Enforces cache quota by removing the oldest accessed blobs when over limit.
  Future<void> _enforceStorageQuota(Directory dir, int maxBytes) async {
    try {
      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.blob'))
          .toList();

      int currentTotal = 0;
      final fileStats = <({File file, DateTime modified, int length})>[];

      for (final file in files) {
        final stat = await file.stat();
        currentTotal += stat.size;
        fileStats.add((file: file, modified: stat.modified, length: stat.size));
      }

      if (currentTotal > maxBytes) {
        // Sort oldest first
        fileStats.sort((a, b) => a.modified.compareTo(b.modified));
        for (final item in fileStats) {
          if (currentTotal <= maxBytes) break;
          await item.file.delete();
          currentTotal -= item.length;
        }
      }
    } catch (_) {}
  }
}
