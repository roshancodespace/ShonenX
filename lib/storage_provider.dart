import 'dart:io';
import 'package:dartotsu_extension_bridge/Services/Mangayomi/Eval/dart/model/source_preference.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shonenx/core/models/offline/chapter.dart';
import 'package:shonenx/core/models/offline/manga.dart';
import 'package:shonenx/core/models/offline/track.dart';
import 'package:shonenx/data/isar/models/isar_anime_watch_progress.dart';

class StorageProvider {
  static Future<void> deleteBtDirectory() async {
    final d = await getBtDirectory();
    await Directory(d!.path).delete(recursive: true);
  }

  static Future<Directory?> getDefaultDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/ShonenX/");
    } else {
      final dir = await getApplicationDocumentsDirectory();
      directory = Directory(path.join(dir.path, 'ShonenX'));
    }
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
    final dir = await getApplicationDocumentsDirectory();
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return dir;
    } else {
      String dbDir = path.join(dir.path, 'ShonenX', 'databases');
      await Directory(dbDir).create(recursive: true);
      return Directory(dbDir);
    }
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
        MangaSchema,
        MSourceSchema,
        ChapterSchema,
        SourcePreferenceSchema,
        TrackSchema,
        SourcePreferenceStringValueSchema,
        BridgeSettingsSchema,
        IsarAnimeWatchProgressSchema,
      ],
      directory: dir!.path,
      name: "shonenxDb",
      inspector: inspector!,
    );

    return isar;
  }
}
