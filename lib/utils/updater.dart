import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:shonenx/core/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks for ShonenX updates to notify user
Future<void> checkForUpdates(BuildContext context) async {
  try {
    // Step 1: Get the latest release from GitHub
    const repo = 'Darkx-dev/ShonenX';
    final url = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
    final response = await http.get(url, headers: {
      'Accept': 'application/vnd.github.v3+json',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      AppLogger.w('Failed to fetch latest release: ${response.statusCode}');
      return;
    }

    final releaseData = jsonDecode(response.body);
    final latestVersion =
        releaseData['tag_name']?.replaceFirst('v', '') ?? '0.0.0';
    developer.log('Latest version from GitHub: $latestVersion',
        name: 'UpdateChecker');

    // Step 2: Get current app version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    developer.log('Current app version: $currentVersion',
        name: 'UpdateChecker');

    // Step 3: Compare versions
    if (_isNewerVersion(latestVersion, currentVersion)) {
      developer.log('Update available: $latestVersion > $currentVersion',
          name: 'UpdateChecker');

      // Step 4: Notify user
      if (!context.mounted) return;
      _notifyUser(context, latestVersion);
    } else {
      developer.log('No update available', name: 'UpdateChecker');
    }
  } catch (e) {
    AppLogger.w('Failed to check for updates: $e');
  }
}

/// Compares two version strings (e.g., "1.2.3" vs "1.2.4")
bool _isNewerVersion(String latest, String current) {
  final latestParts = latest.split('.').map(int.parse).toList();
  final currentParts = current.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
    if (latestParts[i] > currentParts[i]) {
      return true;
    } else if (latestParts[i] < currentParts[i]) {
      return false;
    }
  }
  return false;
}

/// Notifies the user about a new version
void _notifyUser(BuildContext context, String latestVersion) {
  // show alert
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Update Available'),
      content: Text('A new version of ShonenX is available: $latestVersion'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            // open store
            launchUrl(Uri.parse('https://shonenx.vercel.app/#downloads'));
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: const Text('Website'),
        ),
        TextButton(
          onPressed: () {
            // open store
            launchUrl(
                Uri.parse('https://github.com/Darkx-dev/ShonenX/releases'));
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: const Text('Github Releases'),
        ),
      ],
    ),
  );
}
