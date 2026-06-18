import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shonenx/core/remote_config/models/remote_config.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class RemoteConfigUI {
  static Future<void> showUpdateSheet(
    BuildContext context, {
    required ChannelConfig config,
  }) async {
    final bool forceUpdate = config.forceUpdate;

    await AppBottomSheet.show(
      context: context,
      title: 'Update Available',
      enableDrag: !forceUpdate,
      // If forced, tapping outside shouldn't dismiss it.
      child: PopScope(
        canPop: !forceUpdate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Version ${config.version} is now available.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (config.message.isNotEmpty) ...[
              Text(config.message),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!forceUpdate)
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Later'),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    if (config.apk.isNotEmpty) {
                      final url = Uri.parse(config.apk);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
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
      title: 'Announcement',
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
}
