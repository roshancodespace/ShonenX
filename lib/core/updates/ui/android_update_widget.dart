import 'package:flutter/material.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/core/updates/ui/app_update_downloader_widget.dart';

export 'package:shonenx/core/updates/ui/app_update_downloader_widget.dart';

/// Legacy alias for [AppUpdateDownloaderWidget] to ensure 100% backwards compatibility.
class AndroidUpdateWidget extends StatelessWidget {
  final GitHubRelease release;
  final VoidCallback? onDownloadStarted;

  const AndroidUpdateWidget({
    super.key,
    required this.release,
    this.onDownloadStarted,
  });

  static Future<void> show(
    BuildContext context, {
    required GitHubRelease release,
    VoidCallback? onDownloadStarted,
  }) {
    return AppUpdateDownloaderWidget.show(
      context,
      release: release,
      onDownloadStarted: onDownloadStarted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppUpdateDownloaderWidget(
      release: release,
      onDownloadStarted: onDownloadStarted,
    );
  }
}
