import 'dart:io';
import 'package:dartotsu_extension_bridge/Services/Mangayomi/Eval/dart/model/source_preference.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:shonenx/core/models/offline/chapter.dart';
import 'package:shonenx/core/models/offline/manga.dart';
import 'package:shonenx/core/models/offline/track.dart';

class StorageProvider {
  static bool _hasPermission = false;
  Future<bool> requestPermission() async {
    if (_hasPermission) return true;
    if (Platform.isAndroid) {
      Permission permission = Permission.manageExternalStorage;
      if (await permission.isGranted) {
        return true;
      } else {
        final result = await permission.request();
        if (result == PermissionStatus.granted) {
          _hasPermission = true;
          return true;
        }
        return false;
      }
    }
    return true;
  }

  Future<void> deleteBtDirectory() async {
    final d = await getBtDirectory();
    await Directory(d!.path).delete(recursive: true);
  }

  Future<Directory?> getDefaultDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/ShonenX/");
    } else {
      final dir = await getApplicationDocumentsDirectory();
      directory = Directory(path.join(dir.path, 'ShonenX'));
    }
    return directory;
  }

  Future<Directory?> getBtDirectory() async {
    final gefaultDirectory = await getDefaultDirectory();
    String dbDir = path.join(gefaultDirectory!.path, 'torrents');
    await Directory(dbDir).create(recursive: true);
    return Directory(dbDir);
  }

  Future<Directory?> getIosBackupDirectory() async {
    final gefaultDirectory = await getDefaultDirectory();
    String dbDir = path.join(gefaultDirectory!.path, 'backup');
    await Directory(dbDir).create(recursive: true);
    return Directory(dbDir);
  }

  Future<Directory?> getDatabaseDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return dir;
    } else {
      String dbDir = path.join(dir.path, 'ShonenX', 'databases');
      await Directory(dbDir).create(recursive: true);
      return Directory(dbDir);
    }
  }

  Future<Isar> initDB(String? path, {bool? inspector = false}) async {
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
      ],
      directory: dir!.path,
      name: "shonenxDb",
      inspector: inspector!,
    );

    return isar;
  }
}
