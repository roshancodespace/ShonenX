// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/utils/update_dialog.dart';

enum UpdateType { stable, beta, alpha, hotfix }

Future<void> checkForUpdates(
  BuildContext context, {
  bool debugMode = false,
  bool includeBeta = false,
  bool includeAlpha = false,
  bool useTestReleases = false,
}) async {
  try {
    final repo = useTestReleases
        ? 'roshancodespace/shonenx-test-releases'
        : 'roshancodespace/ShonenX';

    final pageSize = (includeBeta || includeAlpha) ? 5 : 1;
    final url = Uri.parse(
      'https://api.github.com/repos/$repo/releases?per_page=$pageSize',
    );

    final response = await UniversalHttpClient.instance.get(
      url,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'ShonenX',
      },
    );

    if (response.statusCode != 200) {
      AppLogger.w('Failed to fetch releases: ${response.statusCode}');
      return;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return;

    final List<dynamic> releases = decoded;

    final latestRelease = releases.firstWhere((rel) {
      final tag = (rel['tag_name'] as String).toLowerCase();
      final isPrerelease = rel['prerelease'] as bool;

      if (!isPrerelease) return true;
      if (tag.contains('hotfix')) return true;
      if (includeBeta && tag.contains('beta')) return true;
      if (includeAlpha && tag.contains('alpha')) return true;
      if (useTestReleases && tag.contains('test')) return true;

      return false;
    }, orElse: () => null);

    if (latestRelease == null) return;

    final tagName = latestRelease['tag_name'] ?? '0.0.0';
    final isPrerelease = latestRelease['prerelease'] ?? false;
    final releaseNotes = latestRelease['body'] ?? '';
    final updateType = _determineUpdateType(tagName, isPrerelease);

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = '${packageInfo.version}-${packageInfo.buildNumber}';

    if (debugMode) {
      AppLogger.d('Latest: $tagName | Current: $currentVersion');
    }

    bool isNewer = _isNewerVersion(tagName, currentVersion);

    if (debugMode || isNewer) {
      final assets = latestRelease['assets'] as List<dynamic>;
      String? downloadUrl = _getPlatformSpecificAsset(assets);

      if (!context.mounted) return;

      showUpdateBottomSheet(
        context,
        tagName,
        currentVersion,
        updateType,
        releaseNotes: releaseNotes,
        apkDownloadUrl: downloadUrl,
      );
    } else if (debugMode) {
      showAppSnackBar('No updates', 'You are on the latest allowed version');
    }
  } catch (e) {
    AppLogger.w('Failed to check for updates: $e');
  }
}

String? _getPlatformSpecificAsset(List<dynamic> assets) {
  for (final a in assets) {
    final name = (a['name'] as String).toLowerCase();
    final url = a['browser_download_url'] as String;

    if (Platform.isAndroid &&
        name.contains('arm64-v8a') &&
        name.endsWith('.apk'))
      return url;
    if (Platform.isWindows &&
        (name.endsWith('-setup.exe') || name.contains('windows-portable.zip')))
      return url;
    if (Platform.isLinux && name.contains('linux.zip')) return url;
  }
  return null;
}

UpdateType _determineUpdateType(String tag, bool prerelease) {
  final lowerTag = tag.toLowerCase();
  if (lowerTag.contains('hotfix')) return UpdateType.hotfix;
  if (lowerTag.contains('beta')) return UpdateType.beta;
  if (lowerTag.contains('alpha') || lowerTag.contains('test'))
    return UpdateType.alpha;
  return UpdateType.stable;
}

bool _isNewerVersion(String latestTag, String currentVersion) {
  final latestClean = latestTag.startsWith('v')
      ? latestTag.substring(1)
      : latestTag;

  if (latestClean == currentVersion) return false;

  List<int> getNumbers(String v) {
    return v
        .replaceAll(RegExp(r'[a-zA-Z-]'), '.')
        .split('.')
        .where((s) => s.isNotEmpty)
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }

  final lNums = getNumbers(latestClean);
  final cNums = getNumbers(currentVersion);

  final maxLength = lNums.length > cNums.length ? lNums.length : cNums.length;

  for (int i = 0; i < maxLength; i++) {
    int l = i < lNums.length ? lNums[i] : 0;
    int c = i < cNums.length ? cNums[i] : 0;

    if (l > c) return true;
    if (l < c) return false;
  }

  final bool latestHasSuffix = latestClean.contains('-');
  final bool currentHasSuffix = currentVersion.contains('-');

  if (latestHasSuffix && !currentHasSuffix) return true;
  if (!latestHasSuffix && currentHasSuffix) return false;

  if (latestHasSuffix && currentHasSuffix) {
    return latestClean.compareTo(currentVersion) > 0;
  }

  return false;
}

void showUpdateBottomSheet(
  BuildContext context,
  String latestVersion,
  String currentVersion,
  UpdateType type, {
  String? releaseNotes,
  String? apkDownloadUrl,
}) {
  showGeneralDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => UpdateDialog(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      type: type,
      releaseNotes: releaseNotes,
      apkDownloadUrl: apkDownloadUrl,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
