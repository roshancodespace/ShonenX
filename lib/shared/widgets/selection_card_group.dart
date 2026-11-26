import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

enum _SelectionPosition { single, first, middle, last }

extension _SelectionPositionRadius on _SelectionPosition {
  BorderRadius get radius {
    const outer = Radius.circular(20);
    const inner = Radius.circular(8);
    return switch (this) {
      _SelectionPosition.single => const BorderRadius.all(outer),
      _SelectionPosition.first => const BorderRadius.vertical(
        top: outer,
        bottom: inner,
      ),
      _SelectionPosition.middle => const BorderRadius.all(inner),
      _SelectionPosition.last => const BorderRadius.vertical(
        top: inner,
        bottom: outer,
      ),
    };
  }
}

class _SelectionGroupScope extends InheritedWidget {
  final SettingsStyle style;
  final _SelectionPosition position;

  const _SelectionGroupScope({
    required this.style,
    required this.position,
    required super.child,
  });

  static _SelectionGroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectionGroupScope>();

  @override
  bool updateShouldNotify(_SelectionGroupScope oldWidget) =>
      style != oldWidget.style || position != oldWidget.position;
}

class SelectionCardGroup extends ConsumerWidget {
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

  _SelectionPosition _positionOf(int index) {
    if (children.length == 1) return _SelectionPosition.single;
    if (index == 0) return _SelectionPosition.first;
    if (index == children.length - 1) return _SelectionPosition.last;
    return _SelectionPosition.middle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

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
          if (isClassic)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < children.length; i++)
                    _SelectionGroupScope(
                      style: style,
                      position: _positionOf(i),
                      child: children[i],
                    ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 3),
                  _SelectionGroupScope(
                    style: style,
                    position: _positionOf(i),
                    child: children[i],
                  ),
                ],
              ],
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
    final cs = Theme.of(context).colorScheme;
    final scope = _SelectionGroupScope.maybeOf(context);
    final isClassic = scope?.style == SettingsStyle.classic;
    final radius = (scope?.position ?? _SelectionPosition.single).radius;

    final rowContent = Row(
      children: [
        if (isSubItem) const SizedBox(width: 16),
        if (leading != null) ...[
          if (isClassic)
            SizedBox(width: 28, height: 28, child: Center(child: leading!))
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: leading!,
            ),
          SizedBox(width: isClassic ? 12 : 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isSubItem ? 13 : 14.5,
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
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
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
              ? Icon(Icons.check_rounded, size: 13, color: cs.onPrimary)
              : null,
        ),
      ],
    );

    if (isClassic) {
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
              child: rowContent,
            ),
          ),
          if (showDivider)
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
        ],
      );
    }

    final fill = isSelected
        ? Color.alphaBlend(
            cs.primary.withValues(alpha: 0.12),
            cs.surfaceContainerHigh,
          )
        : cs.surfaceContainerHigh;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isSubItem ? 9 : 11,
            ),
            child: rowContent,
          ),
        ),
      ),
    );
  }
}
