import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static bool notification = false;
  static bool storage = false;
  static bool photos = false;
  static bool videos = false;

  Permissions() {
    checkAll();
  }

  /// Re-checks all permission statuses and updates static fields.
  static Future<void> checkAll() async {
    notification = await Permission.notification.isGranted;
    storage = await Permission.manageExternalStorage.isGranted;
    photos = await Permission.photos.isGranted;
    videos = await Permission.videos.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    if (notification || !Platform.isAndroid) return true;
    final granted = await _request(Permission.notification);
    notification = granted;
    return granted;
  }

  static Future<bool> requestStoragePermission() async {
    if (storage || !Platform.isAndroid) return true;
    final granted = await _request(Permission.manageExternalStorage);
    storage = granted;
    return granted;
  }

  static Future<bool> requestMediaPermissions() async {
    if (photos || videos || !Platform.isAndroid) return true;
    final photosGranted = await _request(Permission.photos);
    final videosGranted = await _request(Permission.videos);
    photos = photosGranted;
    videos = videosGranted;
    return photosGranted && videosGranted;
  }

  static Future<bool> _request(Permission permission) async {
    if (await permission.isGranted || !Platform.isAndroid) {
      return true;
    } else {
      final result = await permission.request();
      if (result == PermissionStatus.granted ||
          result == PermissionStatus.limited) {
        return true;
      }
      return false;
    }
  }
}
