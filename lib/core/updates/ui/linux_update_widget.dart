import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class LinuxUpdateWidget extends StatefulWidget {
  final GitHubRelease? release;
  final bool autoStart;
  final VoidCallback? onDownloadStarted;
  final bool isPreview;

  const LinuxUpdateWidget({
    super.key,
    this.release,
    this.autoStart = false,
    this.onDownloadStarted,
    this.isPreview = false,
  });

  static Future<void> show(
    BuildContext context, {
    GitHubRelease? release,
    bool autoStart = false,
    VoidCallback? onDownloadStarted,
    bool isPreview = false,
  }) async {
    await AppBottomSheet.show(
      context: context,
      title: isPreview ? 'Linux Update (Preview)' : 'Linux Update',
      useRootNavigator: true,
      child: LinuxUpdateWidget(
        release: release,
        autoStart: autoStart,
        onDownloadStarted: onDownloadStarted,
        isPreview: isPreview,
      ),
    );
  }

  @override
  State<LinuxUpdateWidget> createState() => _LinuxUpdateWidgetState();
}

class _LinuxUpdateWidgetState extends State<LinuxUpdateWidget> {
  bool _isUpdating = false;
  bool _updateSuccess = false;
  bool _hasError = false;
  bool _isCancelled = false;
  String _statusMessage = 'Ready to update';
  double _downloadProgress = 0.0;
  bool _showLogs = false;

  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  Process? _process;
  Timer? _previewTimer;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startUpdate();
      });
    }
  }

  @override
  void dispose() {
    _cancelUpdate();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addLog(String message) {
    if (!mounted || _isCancelled) return;
    setState(() {
      _logs.add(message);
    });
    _scrollToBottom();
  }

  void _updateOrAddLog(String message) {
    if (!mounted || _isCancelled) return;
    setState(() {
      if (_logs.isNotEmpty && _logs.last.contains('Downloading:')) {
        _logs[_logs.length - 1] = message;
      } else {
        _logs.add(message);
      }
    });
    _scrollToBottom();
  }

  void _processRawOutput(String rawData) {
    if (!mounted || _isCancelled || !_isUpdating) return;

    final lines = rawData.split(RegExp(r'[\r\n]+'));

    for (final line in lines) {
      if (!mounted || _isCancelled || !_isUpdating) return;

      final clean = line
          .replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '')
          .trim();

      if (clean.isEmpty) continue;

      // Filter out pure curl progress hash lines
      if (clean.replaceAll(RegExp(r'[#\s]'), '').isEmpty) {
        continue;
      }

      // Extract curl percentage
      final percentMatch = RegExp(r'(\d{1,3}(?:\.\d+)?)\s*%').firstMatch(clean);
      if (percentMatch != null &&
          (clean.contains('#') || clean.endsWith('%'))) {
        final pct = double.tryParse(percentMatch.group(1) ?? '');
        if (pct != null) {
          final normalized = (pct / 100.0).clamp(0.0, 1.0);
          setState(() {
            _downloadProgress = normalized;
            _statusMessage = 'Downloading: ${pct.toStringAsFixed(1)}%';
          });
          _updateOrAddLog('[*] Downloading: ${pct.toStringAsFixed(1)}%');
        }
        continue;
      }

      if (clean.contains('civis') || clean.contains('cnorm')) continue;

      if (clean.contains('extracting to')) {
        setState(() {
          _statusMessage = 'Extracting update bundle...';
        });
      } else if (clean.contains('linked to')) {
        setState(() {
          _statusMessage = 'Updating executable symlink...';
        });
      }

      _addLog(clean);
    }
  }

  Future<void> _startUpdate() async {
    if (_isUpdating) return;
    widget.onDownloadStarted?.call();

    setState(() {
      _isUpdating = true;
      _updateSuccess = false;
      _hasError = false;
      _isCancelled = false;
      _downloadProgress = 0.0;
      _statusMessage = 'Starting update...';
      _logs.clear();
      _showLogs = true;
    });

    final targetVersion = widget.release?.tagName ?? 'latest';

    if (widget.isPreview) {
      _addLog('[*] Updating to $targetVersion (simulated preview)...');
      int step = 0;
      _previewTimer = Timer.periodic(const Duration(milliseconds: 250), (
        timer,
      ) {
        if (!mounted || _isCancelled) {
          timer.cancel();
          return;
        }
        step++;
        setState(() {
          if (step == 1) {
            _downloadProgress = 0.25;
            _statusMessage = 'Downloading update (25%)...';
            _addLog('[*] Downloading: 25.0%');
          } else if (step == 2) {
            _downloadProgress = 0.65;
            _statusMessage = 'Downloading update (65%)...';
            _updateOrAddLog('[*] Downloading: 65.0%');
          } else if (step == 3) {
            _downloadProgress = 1.0;
            _statusMessage = 'Extracting update bundle...';
            _updateOrAddLog('[*] Downloading: 100.0%');
            _addLog('[*] Extracting update bundle...');
          } else if (step == 4) {
            _statusMessage = 'Updating executable symlink...';
            _addLog('[*] Symlinking ShonenX executable...');
          } else if (step >= 5) {
            timer.cancel();
            _isUpdating = false;
            _updateSuccess = true;
            _statusMessage = 'Update complete! Restart ShonenX to apply.';
            _addLog('[+] Update finished successfully. Ready to restart.');
          }
        });
      });
      return;
    }

    final repo = Env.RELEASE_REPO.trim().isNotEmpty
        ? Env.RELEASE_REPO.trim()
        : 'roshancodespace/ShonenX';
    final tagArg = widget.release != null
        ? '--tag ${widget.release!.tagName}'
        : '';

    _addLog('[*] Updating to $targetVersion ($repo)...');

    try {
      final localScript = File('${Directory.current.path}/install.sh');
      final scriptCmd = localScript.existsSync()
          ? 'bash "${localScript.path}" --install --skip-deps $tagArg'
          : 'curl -fsSL https://raw.githubusercontent.com/$repo/main/install.sh | bash -s -- --install --skip-deps $tagArg';

      // Use setsid so the entire subshell and children belong to a single killable process group
      Process process;
      try {
        process = await Process.start('setsid', [
          'bash',
          '-c',
          scriptCmd,
        ], mode: ProcessStartMode.normal);
      } catch (_) {
        process = await Process.start('bash', [
          '-c',
          scriptCmd,
        ], mode: ProcessStartMode.normal);
      }

      if (_isCancelled) {
        try {
          process.kill(ProcessSignal.sigkill);
        } catch (_) {}
        return;
      }

      _process = process;

      _stdoutSub = process.stdout
          .transform(utf8.decoder)
          .listen(_processRawOutput);
      _stderrSub = process.stderr
          .transform(utf8.decoder)
          .listen(_processRawOutput);

      final exitCode = await process.exitCode;
      _process = null;

      if (!mounted || _isCancelled) return;

      if (exitCode == 0) {
        setState(() {
          _isUpdating = false;
          _downloadProgress = 1.0;
          _updateSuccess = true;
          _statusMessage = 'Update complete! Restart ShonenX to apply.';
        });
        _addLog('[+] Installation complete. Ready to restart.');
      } else {
        setState(() {
          _isUpdating = false;
          _hasError = true;
          _statusMessage = 'Update failed (code $exitCode).';
        });
        _addLog('[!] Installer exited with code $exitCode.');
      }
    } catch (e) {
      if (!mounted || _isCancelled) return;
      setState(() {
        _isUpdating = false;
        _hasError = true;
        _statusMessage = 'Failed to run updater: $e';
      });
      _addLog('[!] Error: $e');
    }
  }

  Future<void> _cancelUpdate() async {
    _isCancelled = true;
    _previewTimer?.cancel();

    // 1. Immediately detach stream listeners
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;

    final proc = _process;
    _process = null;

    if (proc != null) {
      final pid = proc.pid;
      // 2. Kill the process group (covers bash, subshells, curl, tar)
      try {
        await Process.run('kill', ['-TERM', '-$pid']);
        await Process.run('kill', ['-9', '-$pid']);
      } catch (_) {}

      // 3. Kill direct child processes
      try {
        await Process.run('pkill', ['-9', '-P', '$pid']);
      } catch (_) {}

      // 4. Force kill the root process
      try {
        proc.kill(ProcessSignal.sigkill);
      } catch (_) {}

      // 5. Clean up any orphaned shonenx installer process
      try {
        await Process.run('pkill', ['-9', '-f', 'install.sh.*--install']);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _isUpdating = false;
      _hasError = false;
      _downloadProgress = 0.0;
      _statusMessage = 'Update cancelled.';
    });
    _addLog('[!] Update cancelled by user.');
  }

  Future<void> _restartApp() async {
    if (widget.isPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '[Preview Mode] On Linux, this launches the updated ShonenX binary and exits the current process.',
          ),
        ),
      );
      return;
    }

    final home = Platform.environment['HOME'] ?? '';
    final binPath = '$home/.local/bin/shonenx';
    final installBinPath = '$home/.local/share/ShonenX/shonenx';

    String targetExe = Platform.resolvedExecutable;
    if (File(binPath).existsSync()) {
      targetExe = binPath;
    } else if (File(installBinPath).existsSync()) {
      targetExe = installBinPath;
    }

    try {
      await Process.start(targetExe, [], mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to auto-restart: $e. Reopen ShonenX manually.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Clean info row matching AndroidUpdateWidget
        Row(
          children: [
            Icon(Icons.terminal_rounded, size: 30, color: cs.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ShonenX ${widget.release?.tagName ?? 'Linux Update'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Linux 64-bit • Quick Update',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (_logs.isNotEmpty)
              IconButton(
                icon: Icon(
                  _showLogs
                      ? Icons.expand_less_rounded
                      : Icons.terminal_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                tooltip: _showLogs ? 'Hide Logs' : 'Show Logs',
                onPressed: () {
                  setState(() {
                    _showLogs = !_showLogs;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Smooth progress bar
        if (_isUpdating) ...[
          LinearProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
        ],

        // Status text
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 12.5,
            color: _hasError ? cs.error : cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        // Inline log console (only visible when updating/requested, clean minimal surface)
        if (_showLogs && _logs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            height: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1419),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final line = _logs[index];
                Color color = const Color(0xFFF8F8F2);
                if (line.contains('[+]')) {
                  color = const Color(0xFF50FA7B);
                } else if (line.contains('[!]')) {
                  color = const Color(0xFFFF5555);
                } else if (line.contains('[*]')) {
                  color = const Color(0xFF8BE9FD);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    line,
                    style: TextStyle(
                      color: color,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Primary action buttons
        if (_updateSuccess) ...[
          FilledButton.icon(
            onPressed: _restartApp,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restart ShonenX'),
          ),
        ] else if (_hasError) ...[
          FilledButton.icon(
            onPressed: _startUpdate,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Update'),
          ),
        ] else if (!_isUpdating) ...[
          FilledButton.icon(
            onPressed: _startUpdate,
            icon: const Icon(Icons.system_update_alt_rounded),
            label: const Text('Update Now'),
          ),
        ] else ...[
          OutlinedButton(onPressed: _cancelUpdate, child: const Text('Cancel')),
        ],
      ],
    );
  }
}
