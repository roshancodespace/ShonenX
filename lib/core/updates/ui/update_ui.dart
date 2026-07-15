import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/core/updates/ui/android_update_widget.dart';
import 'package:shonenx/core/updates/ui/linux_update_widget.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class UpdateUI {
  static String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static Future<void> showReleaseSheet(
    BuildContext context, {
    required GitHubRelease release,
    VoidCallback? onDismiss,
    VoidCallback? onDownload,
  }) async {
    await AppBottomSheet.show(
      context: context,
      title: onDismiss != null ? 'Update Available' : release.name,
      useRootNavigator: true,
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onDismiss != null) ...[
            Text(
              release.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: release.prerelease
                      ? Theme.of(context).colorScheme.tertiaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  release.prerelease ? 'Pre-release' : 'Stable',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: release.prerelease
                        ? Theme.of(context).colorScheme.onTertiaryContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Released on ${_formatDate(release.publishedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: MarkdownBody(
                  data: release.body.trim().isEmpty
                      ? 'No release notes provided.'
                      : release.body.trim(),
                  selectable: true,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrl(
                        Uri.parse(href),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                        h1: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        code: TextStyle(
                          fontFamily: 'monospace',
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        blockquote: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onDismiss != null)
                TextButton(
                  onPressed: () {
                    onDismiss();
                    context.pop();
                  },
                  child: const Text('Later'),
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(release.htmlUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: const Text('GitHub'),
              ),
              if (Platform.isLinux)
                OutlinedButton.icon(
                  onPressed: () {
                    onDownload?.call();
                    context.pop();
                    LinuxUpdateWidget.show(context);
                  },
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  label: const Text('Terminal Install'),
                ),
              if (Platform.isAndroid)
                FilledButton.icon(
                  onPressed: () {
                    onDownload?.call();
                    context.pop();
                    AndroidUpdateWidget.show(
                      context,
                      release: release,
                      onDownloadStarted: onDownload,
                    );
                  },
                  icon: const Icon(Icons.install_mobile_rounded, size: 18),
                  label: const Text('In-App Install'),
                )
              else if (release.downloadUrl != null ||
                  release.htmlUrl.isNotEmpty)
                FilledButton.icon(
                  onPressed: () async {
                    onDownload?.call();
                    context.pop();
                    final url = Uri.parse(
                      release.downloadUrl ?? release.htmlUrl,
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> showReleaseUpdateSheet(
    BuildContext context, {
    required GitHubRelease release,
    required VoidCallback onDismiss,
    required VoidCallback onDownload,
  }) {
    return showReleaseSheet(
      context,
      release: release,
      onDismiss: onDismiss,
      onDownload: onDownload,
    );
  }
}
