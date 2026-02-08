import 'dart:io';

import 'package:dartotsu_extension_bridge/Settings/Settings.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ExtensionManager.dart';
import 'Services/Aniyomi/AniyomiExtensions.dart';
import 'Services/Mangayomi/Eval/dart/model/source_preference.dart';
import 'Services/Mangayomi/MangayomiExtensions.dart';
import 'Services/Mangayomi/Models/Source.dart';

late Isar isar;
WebViewEnvironment? webViewEnvironment;
Client? httpClient;

class DartotsuExtensionBridge {
  Future<void> init(Isar? isarInstance, String dirName, {Client? http}) async {
    httpClient = http;
    if (isarInstance == null) {
      var document = await getDatabaseDirectory(dirName);
      isar = Isar.openSync(
        isarSchema,
        directory: p.join(document.path, 'isar'),
      );
    } else {
      isar = isarInstance;
    }
    final settings = await isar.bridgeSettings
        .filter()
        .idEqualTo(26)
        .findFirst();
    if (settings == null) {
      isar.writeTxnSync(
        () => isar.bridgeSettings.putSync(BridgeSettings()..id = 26),
      );
    }
    if (Platform.isAndroid) {
      Get.lazyPut(() => AniyomiExtensions(), tag: 'AniyomiExtensions');
    }
    Get.lazyPut(() => MangayomiExtensions(), tag: 'MangayomiExtensions');
    Get.lazyPut(() => ExtensionManager());
    if (Platform.isWindows) {
      final availableVersion = await WebViewEnvironment.getAvailableVersion();
      if (availableVersion != null) {
        webViewEnvironment = await WebViewEnvironment.create(
          settings: WebViewEnvironmentSettings(
            userDataFolder: p.join(
              (await getDatabaseDirectory(dirName)).path,
              'flutter_inappwebview',
            ),
          ),
        );
      }
    }
  }

  static var isarSchema = [
    MSourceSchema,
    SourcePreferenceSchema,
    SourcePreferenceStringValueSchema,
    BridgeSettingsSchema,
  ];
}

Future<Directory> getDatabaseDirectory(String dirName) async {
  final dir = await getApplicationDocumentsDirectory();
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    return dir;
  } else {
    String dbDir = p.join(dir.path, dirName, 'databases');
    await Directory(dbDir).create(recursive: true);
    return Directory(dbDir);
  }
}
