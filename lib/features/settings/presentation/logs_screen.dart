import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _logs = '';
  List<String> _logLines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await AppLogger.getLogContent();
    if (mounted) {
      setState(() {
        _logs = logs;
        _logLines = logs.split('\n');
        _isLoading = false;
      });
    }
  }

  Future<void> _copyLogs() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard')));
    }
  }

  Future<void> _exportLogs() async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save App Logs',
        fileName: 'shonenx_logs.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsString(_logs);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logs exported to $path')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export logs: $e')));
      }
    }
  }

  Color _getLogColor(BuildContext context, String line) {
    final colorScheme = Theme.of(context).colorScheme;
    if (line.contains('[ERROR]') || line.contains('✗')) {
      return colorScheme.error;
    } else if (line.contains('[WARN]') || line.contains('⚠')) {
      return Colors.orange;
    } else if (line.contains('[INFO]')) {
      return Colors.lightBlue;
    } else if (line.contains('[DEBUG]') || line.contains('[VERBOSE]')) {
      return colorScheme.onSurfaceVariant;
    } else if (line.contains('[SUCCESS]') || line.contains('✓')) {
      return Colors.green;
    } else if (line.contains('===')) {
      return Colors.pinkAccent;
    }
    return colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return AppScaffold(
      title: 'Diagnostics & Logs',
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_rounded),
          tooltip: 'Copy to Clipboard',
          onPressed: _logs.isEmpty || _logs == 'No logs available.'
              ? null
              : _copyLogs,
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded),
          tooltip: 'Export Logs',
          onPressed: _logs.isEmpty || _logs == 'No logs available.'
              ? null
              : _exportLogs,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Logs',
          onPressed: _loadLogs,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SelectionArea(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                itemCount: _logLines.length,
                itemBuilder: (context, index) {
                  final line = _logLines[index];
                  if (line.trim().isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.4,
                        color: _getLogColor(context, line),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
