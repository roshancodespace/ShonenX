import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:install_plugin/install_plugin.dart';

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
  final typeText = type.name.toUpperCase();
  final colorScheme = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      double progress = 0.0;
      bool downloading = false;

      return StatefulBuilder(builder: (context, setState) {
        Future<void> downloadAndInstall() async {
          if (apkDownloadUrl == null) return;
          setState(() {
            downloading = true;
            progress = 0;
          });

          final tempDir = await getTemporaryDirectory();
          final savePath = '${tempDir.path}/app-update.apk';

          try {
            await Dio().download(
              apkDownloadUrl,
              savePath,
              onReceiveProgress: (rec, total) {
                setState(() {
                  progress = rec / total;
                });
              },
            );
            developer.log('Downloaded APK: $savePath');

            await InstallPlugin.install(savePath, appId: 'com.example.shonenx')
                .then((_) async {
              developer.log('Install triggered');
            }).catchError((e) {
              developer.log('Installation failed: $e');
            });
          } catch (e) {
            developer.log('Download failed: $e');
          } finally {
            if (await File(savePath).exists()) {
              await File(savePath).delete();
              developer.log('Deleted APK file after install or failure');
            }
            setState(() {
              downloading = false;
              progress = 0;
            });
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Available',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            typeText,
                            style: TextStyle(
                              color: type == UpdateType.stable
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSecondary,
                            ),
                          ),
                          backgroundColor: type == UpdateType.stable
                              ? colorScheme.primary
                              : colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => launchUrl(Uri.parse(
                              'https://shonenx.vercel.app/#downloads')),
                          icon: const Icon(Icons.public, size: 20),
                          tooltip: 'Website',
                        ),
                        IconButton(
                          onPressed: () => launchUrl(Uri.parse(
                              'https://github.com/roshancodespace/ShonenX/releases')),
                          icon: const Icon(Icons.code, size: 20),
                          tooltip: 'GitHub',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Version',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(currentVersion,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Latest Version',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(latestVersion,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (releaseNotes != null && releaseNotes.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Release Notes',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(releaseNotes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                    ],
                  ),
                Text(
                  'You can download and install this update directly from the app.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: downloading
                      ? LinearProgressIndicator(value: progress)
                      : ElevatedButton.icon(
                          onPressed: apkDownloadUrl == null
                              ? null
                              : downloadAndInstall,
                          icon: const Icon(Icons.download),
                          label: const Text('Download & Install'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      });
    },
  );
}
