import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/utils/updater.dart';
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

  Future<void> _downloadAndInstall() async {
    if (widget.apkDownloadUrl == null) return;

    setState(() {
      _downloading = true;
      _progress = 0;
      _statusMessage = "Starting download...";
      _error = false;
    });

    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/app-update.apk';

    try {
      if (await File(savePath).exists()) {
        await File(savePath).delete();
      }

      await Dio().download(
        widget.apkDownloadUrl!,
        savePath,
        onReceiveProgress: (rec, total) {
          if (mounted) {
            setState(() {
              _progress = rec / total;
              _statusMessage =
                  "Downloading... ${(_progress * 100).toStringAsFixed(0)}%";
            });
          }
        },
      );

      developer.log('Downloaded APK: $savePath');
      if (mounted) {
        setState(() {
          _statusMessage = "Installing...";
        });
      }

      await InstallPlugin.install(savePath, appId: 'com.example.shonenx')
          .then((_) async {
            developer.log('Install triggered');
          })
          .catchError((e) {
            developer.log('Installation failed: $e');
            if (mounted) {
              setState(() {
                _error = true;
                _statusMessage = "Installation failed: $e";
                _downloading = false;
              });
            }
          });
    } catch (e) {
      developer.log('Download failed: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _statusMessage = "Download failed. Please try again.";
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeText = widget.type.name.toUpperCase();
    final isStable = widget.type == UpdateType.stable;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GlassContainer.clearGlass(
          height: MediaQuery.of(context).size.height * 0.8,
          width: double.infinity,
          borderRadius: BorderRadius.circular(24),
          borderWidth: 1.0,
          borderColor: Colors.white.withOpacity(0.2),
          elevation: 10,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isStable
                            ? colorScheme.primary.withOpacity(0.2)
                            : colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: isStable
                            ? colorScheme.primary
                            : colorScheme.secondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Available',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isStable
                                      ? colorScheme.primary
                                      : colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.currentVersion} ➔ ${widget.latestVersion}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.releaseNotes != null &&
                          widget.releaseNotes!.isNotEmpty) ...[
                        Text(
                          "What's New",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        MarkdownBody(
                          data: widget.releaseNotes!,
                          styleSheet: MarkdownStyleSheet(
                            p: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            listBullet: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            h1: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.black.withOpacity(0.3),
                              color: Colors.amberAccent,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              launchUrl(Uri.parse(href));
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // External Links
                      Row(
                        children: [
                          _buildLinkButton(
                            icon: Icons.public,
                            label: "Website",
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://shonenx.vercel.app/#downloads',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildLinkButton(
                            icon: Icons.code,
                            label: "GitHub",
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://github.com/roshancodespace/ShonenX/releases',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Footer (Action)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_downloading || _error) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _statusMessage ?? "",
                            style: TextStyle(
                              color: _error
                                  ? Colors.redAccent
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          if (_downloading)
                            Text(
                              "${(_progress * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _downloading ? _progress : (_error ? 0 : 1),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _error ? Colors.redAccent : colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_downloading || widget.apkDownloadUrl == null)
                            ? null
                            : _downloadAndInstall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isStable
                              ? colorScheme.primary
                              : colorScheme.secondary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withOpacity(
                            0.1,
                          ),
                          disabledForegroundColor: Colors.white.withOpacity(
                            0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: _downloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          _downloading ? 'Downloading...' : 'Update Now',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
