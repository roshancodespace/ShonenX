import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  DeviceInfo._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static AndroidDeviceInfo? _cachedInfo;

  static Future<AndroidDeviceInfo> _info() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('This device is not Android');
    }

    return _cachedInfo ??= await _deviceInfo.androidInfo;
  }

  static Future<bool> isAndroid10OrBelow() async {
    final info = await _info();
    return info.version.sdkInt <= 29;
  }

  static Future<bool> isAndroid11OrAbove() async {
    final info = await _info();
    return info.version.sdkInt >= 30;
  }
}
