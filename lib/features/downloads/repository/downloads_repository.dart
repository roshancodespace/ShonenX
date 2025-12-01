import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';

class DownloadsRepository {
  static const String boxName = 'downloads';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<DownloadItem>(boxName);
    }
  }

  Box<DownloadItem> get _box => Hive.box<DownloadItem>(boxName);

  List<DownloadItem> getDownloads() {
    return _box.values.toList();
  }

  Future<void> saveDownload(DownloadItem item) async {
    await _box.put(item.filePath, item);
  }

  Future<void> deleteDownload(String filePath) async {
    await _box.delete(filePath);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
