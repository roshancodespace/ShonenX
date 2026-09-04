import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

class SelectionCardGroup extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry headerPadding;
  final Widget? trailingHeader;

  const SelectionCardGroup({
    super.key,
    this.title,
    this.subtitle,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.headerPadding = const EdgeInsets.only(left: 4, bottom: 10),
    this.trailingHeader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = GlobalUI.uiRoundness;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || subtitle != null) ...[
            Padding(
              padding: headerPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if (title != null && subtitle != null)
                          const SizedBox(height: 4),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailingHeader != null) trailingHeader!,
                ],
              ),
            ),
          ],
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ],
      ),
    );
  }
}

class SelectionCardTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool isSelected;
  final bool showDivider;
  final bool isSubItem;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SelectionCardTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.isSelected,
    this.showDivider = false,
    this.isSubItem = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            color: isSelected && isSubItem
                ? cs.primaryContainer.withValues(alpha: 0.15)
                : Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isSubItem ? 10 : 12,
            ),
            child: Row(
              children: [
                if (isSubItem) const SizedBox(width: 16),
                if (leading != null) ...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(child: leading!),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: isSubItem ? 13 : 14,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      if (subtitleWidget != null) ...[
                        const SizedBox(height: 2),
                        subtitleWidget!,
                      ] else if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? cs.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? cs.primary : cs.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
      ],
    );
  }
}