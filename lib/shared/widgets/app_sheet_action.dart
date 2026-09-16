import 'package:flutter/material.dart';

class AppSheetAction extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppSheetAction({
    super.key,
    this.icon,
    this.label,
    this.tooltip,
    required this.onTap,
    this.isPrimary = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    final bg = backgroundColor ?? (isPrimary ? cs.primary : cs.primaryContainer);
    final fg = foregroundColor ?? (isPrimary ? cs.onPrimary : cs.onPrimaryContainer);

    Widget button;
    if (label != null && icon != null) {
      button = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label!),
      );
    } else if (label != null) {
      button = FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
        ),
        onPressed: onTap,
        child: Text(label!),
      );
    } else {
      button = IconButton(
        style: IconButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
        ),
        icon: Icon(icon ?? Icons.circle, size: 20),
        onPressed: onTap,
      );
    }

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
