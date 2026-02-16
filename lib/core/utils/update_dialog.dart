import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/utils/updater.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String currentVersion;
  final UpdateType type;
  final String? releaseNotes;
  final String? apkDownloadUrl;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.currentVersion,
    required this.type,
    this.releaseNotes,
    this.apkDownloadUrl,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0.0;
  bool _downloading = false;
  String? _statusMessage;
  bool _error = false;

  final String _linuxCmd =
      'bash <(curl -fsSL https://raw.githubusercontent.com/Darkx-dev/ShonenX/main/install.sh)';

  Future<void> _handleUpdateAction() async {
    if (Platform.isAndroid) {
      if (widget.apkDownloadUrl == null) return;
      await _downloadAndInstall();
    } else if (Platform.isLinux) {
      await Clipboard.setData(ClipboardData(text: _linuxCmd));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Command copied! Paste it in your terminal.'),
          ),
        );
      }
    } else if (Platform.isWindows) {
      if (widget.apkDownloadUrl == null) return;
      await launchUrl(
        Uri.parse(widget.apkDownloadUrl!),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _statusMessage = "Starting download...";
      _error = false;
    });

    final client = http.Client();
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/app-update.apk';
      final file = File(savePath);
      if (await file.exists()) await file.delete();

      final request = http.Request('GET', Uri.parse(widget.apkDownloadUrl!));
      final response = await client.send(request);

      if (response.statusCode >= 400) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? -1;
      int received = 0;

      final sink = file.openWrite();

      await response.stream
          .listen(
            (chunk) {
              sink.add(chunk);
              received += chunk.length;

              if (mounted && contentLength != -1) {
                setState(() {
                  _progress = received / contentLength;
                  _statusMessage =
                      "Downloading... ${(_progress * 100).toStringAsFixed(0)}%";
                });
              }
            },
            onDone: () async {
              await sink.flush();
              await sink.close();
            },
            onError: (e) async {
              await sink.close();
              throw e;
            },
            cancelOnError: true,
          )
          .asFuture();

      if (mounted) setState(() => _statusMessage = "Installing...");
      await InstallPlugin.install(savePath, appId: 'com.darkx.shonenx');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _statusMessage = "Download failed. Check your connection.";
          _downloading = false;
        });
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLinux = Platform.isLinux;

    final statusColor = widget.type == UpdateType.stable
        ? colorScheme.primary
        : widget.type == UpdateType.hotfix
        ? colorScheme.error
        : colorScheme.tertiary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://github.com/roshancodespace/ShonenX/releases',
                      ),
                    ),
                    icon: const Icon(Icons.code_rounded, size: 18),
                    label: const Text('GitHub'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLinux
                          ? Icons.terminal_rounded
                          : Icons.rocket_launch_rounded,
                      size: 40,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLinux ? 'Update via Terminal' : 'Update Available',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _VersionBadge(
                    current: widget.currentVersion,
                    latest: widget.latestVersion,
                    type: widget.type,
                    color: statusColor,
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLinux) ...[
                      Text(
                        "Run this command:",
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          _linuxCmd,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      "What's New",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data:
                          widget.releaseNotes ?? "No release notes available.",
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_downloading || _error) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _statusMessage ?? "",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _error
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (_downloading)
                          Text(
                            "${(_progress * 100).toInt()}%",
                            style: theme.textTheme.labelMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _downloading ? _progress : 0,
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          (_downloading ||
                              (widget.apkDownloadUrl == null && !isLinux))
                          ? null
                          : _handleUpdateAction,
                      icon: Icon(
                        isLinux
                            ? Icons.content_copy_rounded
                            : Icons.download_rounded,
                      ),
                      label: Text(
                        isLinux
                            ? 'Copy Command'
                            : (_downloading ? 'Downloading...' : 'Update Now'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String current;
  final String latest;
  final UpdateType type;
  final Color color;

  const _VersionBadge({
    required this.current,
    required this.latest,
    required this.type,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '${type.name.toUpperCase()} • $current → $latest',
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
