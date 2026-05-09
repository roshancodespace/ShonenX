import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_apps/device_apps.dart';

class OneDMService {
  OneDMService._();

  static final OneDMService instance = OneDMService._();

  static const List<String> _packages = [
    'idm.internet.download.manager.plus',
    'idm.internet.download.manager',
    'idm.internet.download.manager.adm.lite',
  ];

  static const String _downloaderComponent =
      'idm.internet.download.manager.Downloader';

  String? _cachedPackage;

  Future<String?> getInstalledPackage() async {
    if (_cachedPackage != null) {
      return _cachedPackage;
    }

    for (final package in _packages) {
      final installed = await DeviceApps.isAppInstalled(package);

      if (installed) {
        _cachedPackage = package;
        return package;
      }
    }

    return null;
  }

  Future<bool> download({
    required String url,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }

    final package = await getInstalledPackage();

    if (package == null) {
      return false;
    }

    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: package,
      componentName: _downloaderComponent,
      data: url,
      arguments: {
        if (fileName != null)
          'extra_filename': fileName,

        if (headers != null)
          'android.media.intent.extra.HTTP_HEADERS': headers,
      },
    );

    await intent.launch();

    return true;
  }
}