import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class AppUpdateDownloaderWidget extends StatefulWidget {
  final GitHubRelease release;
  final VoidCallback? onDownloadStarted;

  const AppUpdateDownloaderWidget({
    super.key,
    required this.release,
    this.onDownloadStarted,
  });

  static Future<void> show(
    BuildContext context, {
    required GitHubRelease release,
    VoidCallback? onDownloadStarted,
  }) async {
    final title = _platformTitle();
    await AppBottomSheet.show(
      context: context,
      title: title,
      useRootNavigator: true,
      child: AppUpdateDownloaderWidget(
        release: release,
        onDownloadStarted: onDownloadStarted,
      ),
    );
  }

  static String _platformTitle() {
    if (Platform.isAndroid) return 'Android App Installer';
    if (Platform.isWindows) return 'Windows App Installer';
    if (Platform.isMacOS) return 'macOS App Installer';
    if (Platform.isLinux) return 'Linux Package Installer';
    if (Platform.isIOS) return 'iOS Package Installer';
    return 'App Update Installer';
  }

  @override
  State<AppUpdateDownloaderWidget> createState() =>
      _AppUpdateDownloaderWidgetState();
}

class _AppUpdateDownloaderWidgetState extends State<AppUpdateDownloaderWidget> {
  ReleaseAsset? _bestAsset;
  bool _isLoadingAsset = true;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'Matching compatible build asset...';
  File? _downloadedFile;

  @override
  void initState() {
    super.initState();
    _detectBestAsset();
  }

  Future<void> _detectBestAsset() async {
    final asset = await widget.release.getBestAsset();
    if (mounted) {
      setState(() {
        _bestAsset = asset;
        _isLoadingAsset = false;
        if (asset != null) {
          _statusMessage = 'Ready to download ${asset.name}';
        } else {
          _statusMessage =
              'No compatible package found for this platform in this release.';
        }
      });
    }
  }

  Future<Directory> _resolveTargetDirectory() async {
    if (Platform.isAndroid) {
      final extDirs = await getExternalCacheDirectories();
      if (extDirs != null && extDirs.isNotEmpty) return extDirs.first;
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) return extDir;
      return await getTemporaryDirectory();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
      final appSupport = await getApplicationSupportDirectory();
      return appSupport;
    } else {
      return await getTemporaryDirectory();
    }
  }

  Future<void> _startDownloadAndInstall() async {
    if (_bestAsset == null || _isDownloading) return;
    widget.onDownloadStarted?.call();

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = 'Starting download...';
    });

    try {
      final dir = await _resolveTargetDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}/${_bestAsset!.name}');
      final request = http.Request('GET', Uri.parse(_bestAsset!.downloadUrl));
      request.headers['User-Agent'] = 'KuroX-App';

      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? _bestAsset!.size;
      int receivedBytes = 0;

      final sink = file.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() {
            _progress = receivedBytes / totalBytes;
            final mbReceived =
                (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            final percent = (_progress * 100).toInt();
            _statusMessage =
                'Downloading: $mbReceived MB / $mbTotal MB ($percent%)';
          });
        }
      });

      await sink.flush();
      await sink.close();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _progress = 1.0;
          _statusMessage = 'Download complete! Launching installer...';
          _downloadedFile = file;
        });
      }

      await _triggerInstall(file);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Download failed: $e';
        });
      }
    }
  }

  Future<void> _triggerInstall(File file) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          final res = await Permission.requestInstallPackages.request();
          if (!res.isGranted) {
            if (mounted) {
              setState(() {
                _statusMessage =
                    'Permission to install unknown apps is required to install updates.';
              });
            }
            return;
          }
        }
      }

      final result = await OpenFile.open(file.path);
      if (mounted && result.type != ResultType.done) {
        setState(() {
          _statusMessage =
              'Downloaded to ${file.path}.\nPlease open manually: ${result.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Installer launch note: $e\nFile saved at: ${file.path}';
        });
      }
    }
  }

  IconData _platformIcon() {
    if (Platform.isAndroid) return Icons.android_rounded;
    if (Platform.isWindows) return Icons.desktop_windows_rounded;
    if (Platform.isMacOS) return Icons.laptop_mac_rounded;
    if (Platform.isLinux) return Icons.terminal_rounded;
    if (Platform.isIOS) return Icons.phone_iphone_rounded;
    return Icons.system_update_rounded;
  }

  String _installButtonText() {
    if (Platform.isAndroid) return 'Install APK Now';
    if (Platform.isWindows) return 'Launch Windows Installer';
    if (Platform.isMacOS) return 'Open macOS Package';
    if (Platform.isLinux) return 'Open Linux Package';
    if (Platform.isIOS) return 'Open iOS IPA';
    return 'Open Installer';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoadingAsset) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(_platformIcon(), size: 32, color: cs.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bestAsset?.name ?? 'Unknown Package',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _bestAsset != null
                          ? '${(_bestAsset!.size / (1024 * 1024)).toStringAsFixed(1)} MB • Native Build'
                          : 'No compatible package found',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isDownloading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          _statusMessage,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (_downloadedFile != null) ...[
          FilledButton.icon(
            onPressed: () => _triggerInstall(_downloadedFile!),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_installButtonText()),
          ),
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => OpenFile.open(_downloadedFile!.parent.path),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Show in Folder'),
            ),
          ],
        ] else ...[
          FilledButton.icon(
            onPressed: _bestAsset == null || _isDownloading
                ? null
                : _startDownloadAndInstall,
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _isDownloading ? 'Downloading...' : 'In-App Download & Update',
            ),
          ),
        ],
      ],
    );
  }
}
