import 'dart:io';
import 'package:dartotsu_extension_bridge/Mangayomi/Eval/dart/model/source_preference.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shonenx/data/isar/media.dart';
import 'package:shonenx/data/isar/track.dart';
import 'package:shonenx/data/isar/isar_anime_watch_progress.dart';
import 'package:shonenx/data/isar/isar_source_preference.dart';

class StorageProvider {
  static Future<void> deleteBtDirectory() async {
    final d = await getBtDirectory();
    await Directory(d!.path).delete(recursive: true);
  }

  static Future<Directory?> getDefaultDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final directory = Directory(path.join(dir.path, 'ShonenX'));
    await directory.create(recursive: true);
    return directory;
  }

  static Future<Directory?> getBtDirectory() async {
    final gefaultDirectory = await getDefaultDirectory();
    String dbDir = path.join(gefaultDirectory!.path, 'torrents');
    await Directory(dbDir).create(recursive: true);
    return Directory(dbDir);
  }

  static Future<Directory?> getIosBackupDirectory() async {
    final gefaultDirectory = await getDefaultDirectory();
    String dbDir = path.join(gefaultDirectory!.path, 'backup');
    await Directory(dbDir).create(recursive: true);
    return Directory(dbDir);
  }

  static Future<Directory?> getDatabaseDirectory() async {
    final dir = await getApplicationSupportDirectory();
    return dir;
  }

  static Future<Isar> initDB(String? path, {bool? inspector = false}) async {
    Directory? dir;
    if (path == null) {
      dir = await getDatabaseDirectory();
    } else {
      dir = Directory(path);
    }

    final isar = await Isar.open(
      [
        MediaSchema,
        MSourceSchema,
        SourcePreferenceSchema,
        TrackSchema,
        SourcePreferenceStringValueSchema,
        BridgeSettingsSchema,
        IsarAnimeWatchProgressSchema,
        IsarSourcePreferenceSchema,
      ],
      directory: dir!.path,
      name: "shonenxDb",
      inspector: inspector!,
    );

    return isar;
  }
}
