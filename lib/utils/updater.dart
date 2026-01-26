import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/main.dart';
import 'package:dio/dio.dart';
import 'package:shonenx/utils/update_dialog.dart';

enum UpdateType { stable, beta, alpha, hotfix }

Future<void> checkForUpdates(
  BuildContext context, {
  bool debugMode = false,
  bool includeBeta = false,
  bool includeAlpha = false,
}) async {
  try {
    const repo = 'roshancodespace/ShonenX';
    final url = Uri.parse('https://api.github.com/repos/$repo/releases');

    final response = await Dio().get(
      url.toString(),
      options: Options(
        headers: {'Accept': 'application/vnd.github.v3+json'},
        responseType: ResponseType.json,
      ),
    );

    if (response.statusCode != 200 || response.data is! List) {
      AppLogger.w('Failed to fetch releases');
      return;
    }

    final List<dynamic> releases = response.data;
    if (releases.isEmpty) return;

    final latestRelease = releases.firstWhere((rel) {
      final tag = (rel['tag_name'] as String).toLowerCase();
      final isPrerelease = rel['prerelease'] as bool;

      if (!isPrerelease) return true;
      if (tag.contains('hotfix')) return true;
      if (includeBeta && tag.contains('beta')) return true;
      if (includeAlpha && tag.contains('alpha')) return true;

      return false;
    }, orElse: () => null);

    if (latestRelease == null) return;

    final tagName = latestRelease['tag_name'] ?? '0.0.0';
    final isPrerelease = latestRelease['prerelease'] ?? false;
    final releaseNotes = latestRelease['body'] ?? '';
    final updateType = _determineUpdateType(tagName, isPrerelease);

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

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
  if (Platform.isAndroid) {
    return assets.firstWhere(
      (a) =>
          (a['name'] as String).contains('arm64-v8a') &&
          (a['name'] as String).endsWith('.apk'),
      orElse: () => null,
    )?['browser_download_url'];
  } else if (Platform.isWindows) {
    return assets.firstWhere(
      (a) => (a['name'] as String).endsWith('-Setup.exe'),
      orElse: () => assets.firstWhere(
        (a) => (a['name'] as String).contains('Windows-Portable.zip'),
        orElse: () => null,
      ),
    )?['browser_download_url'];
  } else if (Platform.isLinux) {
    return assets.firstWhere(
      (a) => (a['name'] as String).contains('Linux.zip'),
      orElse: () => null,
    )?['browser_download_url'];
  }
  return null;
}

UpdateType _determineUpdateType(String tag, bool prerelease) {
  final lowerTag = tag.toLowerCase();
  if (lowerTag.contains('hotfix')) return UpdateType.hotfix;
  if (lowerTag.contains('beta')) return UpdateType.beta;
  if (lowerTag.contains('alpha')) return UpdateType.alpha;
  return UpdateType.stable;
}

bool _isNewerVersion(String latestTag, String currentVersion) {
  final latestClean = latestTag.startsWith('v')
      ? latestTag.substring(1)
      : latestTag;
  if (latestClean == currentVersion) return false;

  List<dynamic> parseVersion(String v) {
    final mainParts = v.split('-');
    final numericPart = mainParts[0];
    final numbers = numericPart
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    int subPatch = 0;
    String label = '';

    if (mainParts.length > 1) {
      label = mainParts[1]; // e.g., hotfix.1
      final subMatch = RegExp(r'\.(\d+)').firstMatch(label);
      if (subMatch != null) {
        subPatch = int.tryParse(subMatch.group(1)!) ?? 0;
      }
    }

    return [numbers, label, subPatch];
  }

  final latestData = parseVersion(latestClean);
  final currentData = parseVersion(currentVersion);

  final List<int> lNums = latestData[0];
  final List<int> cNums = currentData[0];

  for (int i = 0; i < 3; i++) {
    int l = i < lNums.length ? lNums[i] : 0;
    int c = i < cNums.length ? cNums[i] : 0;
    if (l > c) return true;
    if (l < c) return false;
  }

  final String lLabel = latestData[1];
  final String cLabel = currentData[1];
  final int lSub = latestData[2];
  final int cSub = currentData[2];

  if (lLabel.isEmpty && cLabel.isNotEmpty) return true;
  if (lLabel.isNotEmpty && cLabel.isEmpty) return false;

  if (lLabel.isNotEmpty && cLabel.isNotEmpty) {
    final lType = lLabel.split('.')[0];
    final cType = cLabel.split('.')[0];

    if (lType == cType) {
      return lSub > cSub;
    }
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
        curve: Curves.easeInOutCubicEmphasized,
        reverseCurve: Curves.easeInOutCubicEmphasized,
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
