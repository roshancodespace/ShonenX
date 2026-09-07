import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class WindowsUpdateWidget extends StatefulWidget {
  final GitHubRelease release;
  final VoidCallback? onDownloadStarted;
  final bool isPreview;

  const WindowsUpdateWidget({
    super.key,
    required this.release,
    this.onDownloadStarted,
    this.isPreview = false,
  });

  static Future<void> show(
    BuildContext context, {
    required GitHubRelease release,
    VoidCallback? onDownloadStarted,
    bool isPreview = false,
  }) async {
    await AppBottomSheet.show(
      context: context,
      title: isPreview ? 'Windows Update (Preview)' : 'Windows Update',
      useRootNavigator: true,
      child: WindowsUpdateWidget(
        release: release,
        onDownloadStarted: onDownloadStarted,
        isPreview: isPreview,
      ),
    );
  }

  @override
  State<WindowsUpdateWidget> createState() => _WindowsUpdateWidgetState();
}

class _WindowsUpdateWidgetState extends State<WindowsUpdateWidget> {
  ReleaseAsset? _bestAsset;
  bool _isLoadingAsset = true;
  bool _isDownloading = false;
  bool _isCancelled = false;
  double _progress = 0.0;
  String _statusMessage = 'Checking for Windows installer...';
  File? _downloadedFile;
  File? _currentFile;
  IOSink? _currentSink;
  bool _installerLaunched = false;
  String? _errorMessage;
  http.Client? _httpClient;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    _detectBestAsset();
  }

  @override
  void dispose() {
    _cancelDownload();
    super.dispose();
  }

  Future<void> _detectBestAsset() async {
    var asset = await widget.release.getBestAsset();

    if (widget.isPreview && (asset == null || !asset.name.endsWith('.exe'))) {
      asset = const ReleaseAsset(
        name: 'ShonenX-x86_64-2.2.0-Installer.exe',
        downloadUrl: 'https://github.com/roshancodespace/ShonenX/releases',
        size: 50855936,
      );
    }

    if (!mounted) return;

    setState(() {
      _bestAsset = asset;
      _isLoadingAsset = false;
      if (asset != null) {
        final sizeMb = (asset.size / (1024 * 1024)).toStringAsFixed(1);
        _statusMessage = 'Ready to download ($sizeMb MB)';
      } else {
        _statusMessage = 'No compatible Windows installer found.';
        _errorMessage = 'No Windows .exe found in this release.';
      }
    });

    if (asset != null) {
      _startDownloadAndInstall();
    }
  }

  Future<void> _cancelDownload() async {
    _isCancelled = true;
    _previewTimer?.cancel();
    _httpClient?.close();

    try {
      await _currentSink?.flush();
      await _currentSink?.close();
    } catch (_) {}
    _currentSink = null;

    if (_currentFile != null && await _currentFile!.exists()) {
      try {
        await _currentFile!.delete();
      } catch (_) {}
    }
    _currentFile = null;

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _statusMessage = 'Download cancelled.';
    });
  }

  Future<void> _startDownloadAndInstall() async {
    if (_bestAsset == null || _isDownloading) return;
    widget.onDownloadStarted?.call();

    setState(() {
      _isDownloading = true;
      _isCancelled = false;
      _errorMessage = null;
      _progress = 0.0;
      _statusMessage = 'Starting download...';
    });

    if (widget.isPreview) {
      final totalBytes = _bestAsset!.size;
      final mbTotal = (totalBytes / (1024 * 1024));

      _previewTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
        if (!mounted || _isCancelled) {
          timer.cancel();
          return;
        }
        setState(() {
          _progress += 0.04;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _isDownloading = false;
            _installerLaunched = true;
            _statusMessage =
                'Installer launched! Please exit ShonenX to finish installation.';
            timer.cancel();
          } else {
            final mbReceived = (mbTotal * _progress).toStringAsFixed(1);
            final percent = (_progress * 100).toInt();
            _statusMessage =
                'Downloading: $mbReceived MB / ${mbTotal.toStringAsFixed(1)} MB ($percent%)';
          }
        });
      });
      return;
    }

    _httpClient = http.Client();

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _bestAsset!.name.isNotEmpty
          ? _bestAsset!.name
          : 'ShonenX-Setup.exe';
      final file = File(p.join(tempDir.path, fileName));
      _currentFile = file;

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final request = http.Request('GET', Uri.parse(_bestAsset!.downloadUrl));
      request.headers['User-Agent'] = 'ShonenX-App';

      final response = await _httpClient!.send(request);
      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      if (_isCancelled) return;

      final totalBytes = response.contentLength ?? _bestAsset!.size;
      int receivedBytes = 0;
      final sink = file.openWrite();
      _currentSink = sink;

      await response.stream.forEach((chunk) {
        if (_isCancelled) return;
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() {
            _progress = receivedBytes / totalBytes;
            final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(
              1,
            );
            final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            final percent = (_progress * 100).toInt();
            _statusMessage =
                'Downloading: $mbReceived MB / $mbTotal MB ($percent%)';
          });
        }
      });

      await sink.flush();
      await sink.close();
      _currentSink = null;

      if (!mounted || _isCancelled) return;

      setState(() {
        _isDownloading = false;
        _progress = 1.0;
        _statusMessage = 'Download complete! Launching installer...';
        _downloadedFile = file;
      });

      await _launchInstaller(file);
    } catch (e) {
      if (!mounted || _isCancelled) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = e.toString();
        _statusMessage = 'Download failed: $e';
      });
    }
  }

  Future<void> _launchInstaller(File file) async {
    try {
      await Process.start(file.path, [], mode: ProcessStartMode.detached);
      if (mounted) {
        setState(() {
          _installerLaunched = true;
          _statusMessage =
              'Installer launched! Please exit ShonenX to finish installation.';
        });
      }
    } catch (e) {
      final result = await OpenFile.open(file.path);
      if (mounted) {
        setState(() {
          _installerLaunched = result.type == ResultType.done;
          _statusMessage = _installerLaunched
              ? 'Installer launched! Please exit ShonenX to finish installation.'
              : 'Failed to launch installer: ${result.message}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
        // Simple clean header row matching Android updater style
        Row(
          children: [
            Icon(
              Icons.window_rounded,
              size: 30,
              color: const Color(0xFF0078D4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bestAsset?.name ?? 'ShonenX Windows Installer',
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
                        ? '${(_bestAsset!.size / (1024 * 1024)).toStringAsFixed(1)} MB • Windows 64-bit'
                        : 'No compatible installer',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress bar
        if (_isDownloading) ...[
          LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
        ],

        // Status text
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 12.5,
            color: _errorMessage != null ? cs.error : cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Action buttons
        if (_installerLaunched) ...[
          FilledButton.icon(
            onPressed: () {
              if (widget.isPreview) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '[Preview Mode] On Windows, this exits ShonenX so setup can update files.',
                    ),
                  ),
                );
              } else {
                exit(0);
              }
            },
            icon: const Icon(Icons.exit_to_app_rounded),
            label: const Text('Exit ShonenX & Install'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              if (_downloadedFile != null) {
                _launchInstaller(_downloadedFile!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('[Preview] Installer relaunched!'),
                  ),
                );
              }
            },
            child: const Text('Relaunch Installer'),
          ),
        ] else if (_errorMessage != null) ...[
          FilledButton.icon(
            onPressed: _startDownloadAndInstall,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Download'),
          ),
        ] else if (!_isDownloading && _bestAsset != null) ...[
          FilledButton.icon(
            onPressed: _startDownloadAndInstall,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download & Install'),
          ),
        ] else if (_isDownloading) ...[
          OutlinedButton(
            onPressed: _cancelDownload,
            child: const Text('Cancel'),
          ),
        ],
      ],
    );
  }
}
