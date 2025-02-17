import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shonenx/data/hive/models/continue_watching_model.dart';

class ContinueWatchingBox {
  Box<ContinueWatchingEntry>? _box;
  final String boxName = 'continue_watching';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<ContinueWatchingEntry>(boxName);
    } else {
      _box = Hive.box<ContinueWatchingEntry>(boxName);
    }

  }

  bool get isInitialized => _box != null;

  ValueListenable<Box<ContinueWatchingEntry>> get boxValueListenable => _box!.listenable();

  /// Get a single entry by animeId
  ContinueWatchingEntry? getEntry(int animeId) {
    return _box?.get(animeId);
  }

  /// Add or update an entry
  Future<void> setEntry(ContinueWatchingEntry entry) async {
    await _box?.put(entry.animeId, entry);
  }

  /// Delete an entry by animeId
  Future<void> deleteEntry(int animeId) async {
    await _box?.delete(animeId);
  }

  /// Get all entries
  List<ContinueWatchingEntry> getAllEntries() {
    return _box?.values.toList() ?? [];
  }

  /// Clear all entries
  Future<void> clearAll() async {
    await _box?.deleteAll([_box!.keys]);
  }
}
