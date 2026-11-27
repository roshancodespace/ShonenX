import 'dart:io';

import 'package:flutter_md/flutter_md.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shonenx/features/updates/models/github_release.dart';
import 'package:shonenx/features/updates/ui/android_update_widget.dart';
import 'package:shonenx/features/updates/ui/linux_update_widget.dart';
import 'package:shonenx/features/updates/ui/windows_update_widget.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button.dart';

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
                  borderRadius: BorderRadius.circular(999),
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
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: MarkdownWidget(
                  markdown: Markdown.fromString(
                    release.body.trim().isEmpty
                        ? 'No release notes provided.'
                        : release.body.trim(),
                  ),
                  theme: MarkdownThemeData(
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                    h1Style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    h2Style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    h3Style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    quoteStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    monospaceFontFamily: 'monospace',
                    monospaceBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    linkColor: Theme.of(context).colorScheme.primary,
                    onLinkTap: (title, url) {
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
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
                AppButton(
                  label: 'Later',
                  variant: AppButtonVariant.text,
                  onPressed: () {
                    onDismiss();
                    context.pop();
                  },
                ),
              AppButton(
                label: 'GitHub',
                icon: Icons.open_in_browser_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: () async {
                  final url = Uri.parse(release.htmlUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              if (Platform.isLinux) ...[
                AppButton(
                  label: 'Terminal Command',
                  icon: Icons.terminal_rounded,
                  variant: AppButtonVariant.tonal,
                  onPressed: () {
                    onDownload?.call();
                    context.pop();
                    LinuxUpdateWidget.show(
                      context,
                      release: release,
                      autoStart: false,
                    );
                  },
                ),
                AppButton(
                  label: 'Quick Update',
                  icon: Icons.system_update_alt_rounded,
                  onPressed: () {
                    onDownload?.call();
                    context.pop();
                    LinuxUpdateWidget.show(
                      context,
                      release: release,
                      autoStart: true,
                      onDownloadStarted: onDownload,
                    );
                  },
                ),
              ] else if (Platform.isWindows) ...[
                AppButton(
                  label: 'Update Now',
                  icon: Icons.download_rounded,
                  onPressed: () {
                    onDownload?.call();
                    context.pop();
                    WindowsUpdateWidget.show(
                      context,
                      release: release,
                      onDownloadStarted: onDownload,
                    );
                  },
                ),
              ] else if (Platform.isAndroid) ...[
                AppButton(
                  label: 'In-App Install',
                  icon: Icons.install_mobile_rounded,
                  onPressed: () {
                    onDownload?.call();
                    context.pop();
                    AndroidUpdateWidget.show(
                      context,
                      release: release,
                      onDownloadStarted: onDownload,
                    );
                  },
                ),
              ] else if (release.downloadUrl != null ||
                  release.htmlUrl.isNotEmpty) ...[
                AppButton(
                  label: 'Download',
                  icon: Icons.download_rounded,
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
                ),
              ],
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
