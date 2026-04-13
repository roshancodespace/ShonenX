import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permissions_provider.g.dart';

class PermissionState {
  final bool notification;
  final bool storage;
  final bool photos;
  final bool videos;

  const PermissionState({
    this.notification = false,
    this.storage = false,
    this.photos = false,
    this.videos = false,
  });

  PermissionState copyWith({
    bool? notification,
    bool? storage,
    bool? photos,
    bool? videos,
  }) {
    return PermissionState(
      notification: notification ?? this.notification,
      storage: storage ?? this.storage,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
    );
  }
}

@Riverpod(keepAlive: true)
class Permissions extends _$Permissions {
  int? _cachedSdkInt;

  @override
  PermissionState build() {
    _initSdkInt().then((_) => checkAll());
    return const PermissionState();
  }

  Future<void> checkAll() async {
    if (!Platform.isAndroid) {
      state = state.copyWith(
        notification: true,
        storage: true,
        photos: true,
        videos: true,
      );
      return;
    }
    await _initSdkInt();

    state = state.copyWith(
      notification: await Permission.notification.isGranted,
      storage: await _storagePermission().isGranted,
      photos: await _mediaPermission(Permission.photos).isGranted,
      videos: await _mediaPermission(Permission.videos).isGranted,
    );
  }

  Future<bool> requestNotificationPermission() async {
    if (state.notification || !Platform.isAndroid) return true;
    final granted = await _request(Permission.notification);
    state = state.copyWith(notification: granted);
    return granted;
  }

  Future<bool> requestStoragePermission() async {
    if (state.storage || !Platform.isAndroid) return true;
    await _initSdkInt();
    final granted = await _request(_storagePermission());
    state = state.copyWith(storage: granted);
    return granted;
  }

  Future<bool> requestMediaPermissions() async {
    if (!Platform.isAndroid) return true;
    await _initSdkInt();

    if (_cachedSdkInt! < 33) {
      final granted = await _request(Permission.storage);
      state = state.copyWith(photos: granted, videos: granted);
      return granted;
    }

    final photosGranted = await _request(Permission.photos);
    final videosGranted = await _request(Permission.videos);

    state = state.copyWith(photos: photosGranted, videos: videosGranted);
    return photosGranted && videosGranted;
  }

  Permission _storagePermission() {
    return (_cachedSdkInt ?? 0) >= 30
        ? Permission.manageExternalStorage
        : Permission.storage;
  }

  Permission _mediaPermission(Permission modern) {
    return (_cachedSdkInt ?? 0) >= 33 ? modern : Permission.storage;
  }

  Future<void> _initSdkInt() async {
    if (_cachedSdkInt != null) return;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      _cachedSdkInt = info.version.sdkInt;
    } catch (_) {
      _cachedSdkInt = 0;
    }
  }

  Future<bool> _request(Permission permission) async {
    if (await permission.isGranted || !Platform.isAndroid) return true;
    final result = await permission.request();
    return result == PermissionStatus.granted ||
        result == PermissionStatus.limited;
  }
}
