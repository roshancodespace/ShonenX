import 'package:flutter/material.dart';

class SelectorTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final IconData? leadingIcon;
  final String? subtitle;

  const SelectorTile({
    super.key,
    required this.selected,
    required this.title,
    required this.onTap,
    required this.theme,
    this.leadingIcon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (leadingIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      leadingIcon,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selected
                                  ? colorScheme.primary.withValues(alpha: 0.8)
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 24,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
