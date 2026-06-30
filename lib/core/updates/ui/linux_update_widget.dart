import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class LinuxUpdateWidget extends StatelessWidget {
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
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  command,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                iconSize: 18,
                tooltip: 'Copy Command',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: command));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Installer command copied to clipboard!'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildTag(context, 'Interactive Menu'),
            _buildTag(context, 'Auto Desktop Shortcuts'),
            _buildTag(context, 'Custom Forks & Icons'),
            _buildTag(context, 'shonenx-manager Shortcut'),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}
