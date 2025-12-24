import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/main.dart';
import 'package:dio/dio.dart';
import 'package:shonenx/utils/update_dialog.dart';

enum UpdateType { stable, beta, alpha, hotfix }

Future<void> checkForUpdates(BuildContext context,
    {bool debugMode = false}) async {
  try {
    const repo = 'roshancodespace/ShonenX';
    final url = Uri.parse('https://api.github.com/repos/$repo/releases/latest');

    final response = await Dio().get(
      url.toString(),
      options: Options(
        headers: {'Accept': 'application/vnd.github.v3+json'},
        responseType: ResponseType.json,
      ),
    );

    if (response.statusCode != 200) {
      AppLogger.w('Failed to fetch latest release: ${response.statusCode}');
      return;
    }

    final releaseData = response.data;
    final tagName = releaseData['tag_name'] ?? '0.0.0';
    final isPrerelease = releaseData['prerelease'] ?? false;
    final releaseNotes = releaseData['body'] ?? '';

    final updateType = _determineUpdateType(tagName, isPrerelease);
    final latestVersion = _sanitizeVersion(tagName);

    developer.log('Latest version: $latestVersion (Type: $updateType)',
        name: 'UpdateChecker');

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    developer.log('Current app version: $currentVersion',
        name: 'UpdateChecker');

    // Get APK URL dynamically
    final assets = releaseData['assets'] as List<dynamic>;
    final apkAsset = assets.firstWhere(
      (a) => (a['name'] as String).endsWith('arm64-v8a-release.apk'),
      orElse: () => null,
    );
    String? downloadUrl;
    if (apkAsset != null) {
      downloadUrl = apkAsset['browser_download_url'] as String;
    }

    if (debugMode || _isNewerVersion(latestVersion, currentVersion)) {
      if (!context.mounted) return;
      _notifyUser(
        context,
        latestVersion,
        releaseNotes,
        updateType,
        apkDownloadUrl: downloadUrl,
        currentVersion: currentVersion,
      );
    } else {
      developer.log('No update available', name: 'UpdateChecker');
      showAppSnackBar(
        'No updates',
        'You are already on latest version',
      );
    }
  } catch (e) {
    AppLogger.w('Failed to check for updates: $e');
  }
}

void _notifyUser(
  BuildContext context,
  String latestVersion,
  String? releaseNotes,
  UpdateType type, {
  String? currentVersion,
  String? apkDownloadUrl,
}) {
  showUpdateBottomSheet(
    context,
    latestVersion,
    currentVersion ?? 'unknown',
    type,
    releaseNotes: releaseNotes,
    apkDownloadUrl: apkDownloadUrl,
  );
}

UpdateType _determineUpdateType(String tag, bool prerelease) {
  final lowerTag = tag.toLowerCase();
  if (prerelease) {
    if (lowerTag.contains('alpha')) return UpdateType.alpha;
    if (lowerTag.contains('beta')) return UpdateType.beta;
    if (lowerTag.contains('hotfix')) return UpdateType.hotfix;
  }
  return UpdateType.stable;
}

String _sanitizeVersion(String version) {
  return version
      .split(RegExp(r'[^0-9]'))
      .where((s) => s.isNotEmpty)
      .take(3)
      .join('.');
}

bool _isNewerVersion(String latest, String current) {
  List<int> parseVersion(String version) {
    return version.split('.').map((v) {
      final numStr = RegExp(r'\d+').stringMatch(v);
      return numStr != null ? int.parse(numStr) : 0;
    }).toList();
  }

  final latestParts = parseVersion(latest);
  final currentParts = parseVersion(current);
  final maxLength = latestParts.length > currentParts.length
      ? latestParts.length
      : currentParts.length;

  for (int i = 0; i < maxLength; i++) {
    final l = i < latestParts.length ? latestParts[i] : 0;
    final c = i < currentParts.length ? currentParts[i] : 0;
    if (l > c) return true;
    if (l < c) return false;
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
  // Using showGeneralDialog allows us to have more control over the overlay
  // and ensure it sits on top of everything including the nav bar.
  showGeneralDialog(
    context: context,
    useRootNavigator: true, // This is crucial for covering bottom nav
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return UpdateDialog(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        type: type,
        releaseNotes: releaseNotes,
        apkDownloadUrl: apkDownloadUrl,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        ),
      );
    },
  );
}
