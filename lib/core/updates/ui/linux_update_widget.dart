import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class LinuxUpdateWidget extends StatefulWidget {
  const LinuxUpdateWidget({super.key});

  static Future<void> show(BuildContext context) async {
    await AppBottomSheet.show(
      context: context,
      title: 'Linux Universal Installer',
      useRootNavigator: true,
      child: const LinuxUpdateWidget(),
    );
  }

  @override
  State<LinuxUpdateWidget> createState() => _LinuxUpdateWidgetState();
}

class _LinuxUpdateWidgetState extends State<LinuxUpdateWidget> {
  bool _copied = false;
  Timer? _timer;

  void _copyToClipboard(String command) {
    Clipboard.setData(ClipboardData(text: command));
    _timer?.cancel();

    setState(() {
      _copied = true;
    });

    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Installer command copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final repo = Env.RELEASE_REPO.trim();
    final command =
        'bash -c "\$(curl -fsSL https://raw.githubusercontent.com/$repo/main/install.sh)"';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Run our interactive TUI installer in your terminal to update ShonenX, configure desktop entries, or manage shell shortcuts:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        // Terminal Window Mockup
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1419), // Dark Obsidian background
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Terminal Top Window bar
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF151B23), // Lighter slate for title bar
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Red, Yellow, Green Window Dots (Left)
                    Positioned(
                      left: 0,
                      child: Row(
                        children: [
                          _buildDot(const Color(0xFFFF5F56)),
                          const SizedBox(width: 6),
                          _buildDot(const Color(0xFFFFBD2E)),
                          const SizedBox(width: 6),
                          _buildDot(const Color(0xFF27C93F)),
                        ],
                      ),
                    ),
                    // Terminal Title (Center)
                    Text(
                      'shonenx-installer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Terminal Content Area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Green Terminal Prompt Indicator
                    const Text(
                      r'$ ',
                      style: TextStyle(
                        color: Color(0xFF50FA7B), // Dracula Green
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    // Command text itself
                    Expanded(
                      child: SelectableText(
                        command,
                        style: const TextStyle(
                          color: Color(0xFFF8F8F2),
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Micro-interacting copy button
                    IconButton.filledTonal(
                      onPressed: () => _copyToClipboard(command),
                      style: IconButton.styleFrom(
                        backgroundColor: _copied
                            ? const Color(0xFF27C93F).withValues(alpha: 0.2)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        foregroundColor: _copied
                            ? const Color(0xFF27C93F)
                            : cs.onSurfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        _copied
                            ? Icons.check_circle_outline_rounded
                            : Icons.copy_rounded,
                        size: 18,
                      ),
                      tooltip: 'Copy Command',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTag(context, 'Interactive Menu', Icons.menu_open_rounded),
            _buildTag(
              context,
              'Auto Desktop Shortcuts',
              Icons.shortcut_rounded,
            ),
            _buildTag(context, 'Custom Forks & Icons', Icons.palette_rounded),
            _buildTag(
              context,
              'shonenx-manager Shortcut',
              Icons.terminal_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Dependencies / note container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Note: Ensure that "curl" and "bash" are installed on your Linux distribution before running the command.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTag(BuildContext context, String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.secondaryContainer.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
