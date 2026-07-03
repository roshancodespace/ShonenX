import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/core/updates/ui/linux_update_widget.dart';
import 'package:shonenx/core/updates/ui/android_update_widget.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateUI {
  static Future<void> showReleaseUpdateSheet(
    BuildContext context, {
    required GitHubRelease release,
    required VoidCallback onDismiss,
    required VoidCallback onDownload,
  }) async {
    await AppBottomSheet.show(
      context: context,
      title: 'Update Available',
      useRootNavigator: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  release.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (release.prerelease)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pre-release',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(
                release.body.trim().isEmpty
                    ? 'No release notes provided.'
                    : release.body.trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (Platform.isLinux) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                onDownload();
                context.pop();
                LinuxUpdateWidget.show(context);
              },
              icon: const Icon(Icons.terminal_rounded, size: 18),
              label: const Text('Linux Terminal Installer (Copy Command)'),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  onDismiss();
                  context.pop();
                },
                child: const Text('Later'),
              ),
              const SizedBox(width: 8),
              if (Platform.isAndroid)
                FilledButton.icon(
                  onPressed: () {
                    context.pop();
                    AndroidUpdateWidget.show(
                      context,
                      release: release,
                      onDownloadStarted: onDownload,
                    );
                  },
                  icon: const Icon(Icons.install_mobile_rounded),
                  label: const Text('In-App Download & Install'),
                )
              else
                FilledButton.icon(
                  onPressed: () async {
                    onDownload();
                    context.pop();
                    final url = Uri.parse(release.downloadUrl ?? release.htmlUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Archive'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
