import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shonenx/core/remote_config/models/remote_config.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class RemoteConfigUI {
  static const String _releasesUrl =
      'https://github.com/roshancodespace/shonenx/releases/latest';

  static Future<void> showUpdateSheet(
    BuildContext context, {
    required String minimumVersion,
    required VoidCallback onDownload,
  }) async {
    // This sheet is forced and cannot be dismissed
    await AppBottomSheet.show(
      context: context,
      title: 'Update Required',
      enableDrag: false,
      child: PopScope(
        canPop: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'A critical update to version $minimumVersion is required to continue using the application.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () async {
                    onDownload();
                    final url = Uri.parse(_releasesUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text('Download Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showAnnouncementSheet(
    BuildContext context, {
    required Announcement announcement,
  }) async {
    await AppBottomSheet.show(
      context: context,
      title: announcement.title.isNotEmpty ? announcement.title : 'Announcement',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(announcement.message, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showApplicationDisabledSheet(BuildContext context) async {
    await AppBottomSheet.show(
      context: context,
      title: 'Service Unavailable',
      enableDrag: false,
      child: PopScope(
        canPop: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The application has been disabled by the administrator. Please check back later.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
