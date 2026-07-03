import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;

  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }
}

class GitHubRelease {
  final int id;
  final String tagName;
  final String name;
  final String body;
  final bool prerelease;
  final bool draft;
  final DateTime publishedAt;
  final String htmlUrl;
  final List<ReleaseAsset> assets;

  const GitHubRelease({
    required this.id,
    required this.tagName,
    required this.name,
    required this.body,
    required this.prerelease,
    required this.draft,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
  });

  Future<ReleaseAsset?> getBestAsset() async {
    if (assets.isEmpty) return null;
    if (Platform.isLinux) {
      for (final a in assets) {
        final name = a.name.toLowerCase();
        if (name.contains('linux') &&
            (name.endsWith('.zip') ||
                name.endsWith('.tar.gz') ||
                name.endsWith('.appimage'))) {
          return a;
        }
      }
    } else if (Platform.isWindows) {
      for (final a in assets) {
        final name = a.name.toLowerCase();
        if (name.endsWith('.exe') ||
            (name.contains('win') && name.endsWith('.zip'))) {
          return a;
        }
      }
    } else if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final supportedAbis = androidInfo.supportedAbis.map((e) => e.toLowerCase()).toList();

        for (final abi in supportedAbis) {
          String searchKey = abi;
          if (abi.contains('arm64')) {
            searchKey = 'arm64';
          } else if (abi.contains('armeabi-v7a') || abi.contains('v7a')) searchKey = 'v7a';
          else if (abi.contains('x86_64')) searchKey = 'x86_64';
          else if (abi.contains('x86')) searchKey = 'x86';

          for (final a in assets) {
            final name = a.name.toLowerCase();
            if (name.endsWith('.apk') && name.contains(searchKey)) {
              return a;
            }
          }
        }

        for (final a in assets) {
          final name = a.name.toLowerCase();
          if (name.endsWith('.apk') && (name.contains('universal') || (!name.contains('arm64') && !name.contains('v7a') && !name.contains('x86')))) {
            return a;
          }
        }
      } catch (_) {}

      for (final a in assets) {
        if (a.name.toLowerCase().endsWith('.apk')) {
          return a;
        }
      }
    }
    return assets.first;
  }

  String? get downloadUrl {
    if (assets.isEmpty) return null;
    if (Platform.isLinux) {
      for (final a in assets) {
        final name = a.name.toLowerCase();
        if (name.contains('linux') &&
            (name.endsWith('.zip') ||
                name.endsWith('.tar.gz') ||
                name.endsWith('.appimage'))) {
          return a.downloadUrl;
        }
      }
    } else if (Platform.isWindows) {
      for (final a in assets) {
        final name = a.name.toLowerCase();
        if (name.endsWith('.exe') ||
            (name.contains('win') && name.endsWith('.zip'))) {
          return a.downloadUrl;
        }
      }
    } else if (Platform.isAndroid) {
      for (final a in assets) {
        if (a.name.toLowerCase().endsWith('.apk')) {
          return a.downloadUrl;
        }
      }
    }
    // Fallback if platform specific asset not explicitly named
    return assets.first.downloadUrl;
  }

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assetsList = <ReleaseAsset>[];
    final rawAssets = json['assets'] as List<dynamic>?;
    if (rawAssets != null) {
      for (final item in rawAssets) {
        if (item is Map<String, dynamic>) {
          assetsList.add(ReleaseAsset.fromJson(item));
        }
      }
    }

    final publishedStr =
        json['published_at'] as String? ?? json['created_at'] as String?;
    final publishedDate = publishedStr != null
        ? DateTime.tryParse(publishedStr) ?? DateTime.now()
        : DateTime.now();

    return GitHubRelease(
      id: json['id'] as int? ?? 0,
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? (json['tag_name'] as String? ?? 'New Release'),
      body: json['body'] as String? ?? 'No release notes provided.',
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
      publishedAt: publishedDate,
      htmlUrl: json['html_url'] as String? ?? '',
      assets: assetsList,
    );
  }
}
