import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class AppActionItem {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final String? badge;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AppActionItem({
    required this.icon,
    this.label,
    this.tooltip,
    this.badge,
    required this.onTap,
    this.onLongPress,
  });
}

/// Action button group that renders as M3 Expressive connected/gapped pills in
/// [SettingsStyle.expressive], or as a seamless bordered bar with dividers
/// (like [SegmentedButton]) in [SettingsStyle.classic].
class AppActionButtonGroup extends ConsumerWidget {
  final List<AppActionItem> items;
  final bool outlined;
  final double height;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? backgroundColor;

  const AppActionButtonGroup({
    super.key,
    required this.items,
    this.outlined = true,
    this.height = 38,
    this.foregroundColor,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isClassic =
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle)) ==
        SettingsStyle.classic;

    if (isClassic) {
      final cs = Theme.of(context).colorScheme;
      final effectiveBorder = borderColor ?? cs.outlineVariant;
      final bg =
          backgroundColor ??
          (outlined ? Colors.transparent : cs.surfaceContainerHighest);

      return Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: effectiveBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(width: 1, height: height, color: effectiveBorder),
              _AppActionButton(
                item: items[i],
                isFirst: i == 0,
                isLast: i == items.length - 1,
                isClassic: true,
                outlined: false,
                height: height,
                foregroundColor: foregroundColor,
                borderColor: borderColor,
                backgroundColor: Colors.transparent,
              ),
            ],
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          _AppActionButton(
            item: items[i],
            isFirst: i == 0,
            isLast: i == items.length - 1,
            isClassic: false,
            outlined: outlined,
            height: height,
            foregroundColor: foregroundColor,
            borderColor: borderColor,
            backgroundColor: backgroundColor,
          ),
        ],
      ],
    );
  }
}

class _AppActionButton extends StatefulWidget {
  final AppActionItem item;
  final bool isFirst;
  final bool isLast;
  final bool isClassic;
  final bool outlined;
  final double height;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? backgroundColor;

  const _AppActionButton({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.isClassic,
    required this.outlined,
    required this.height,
    this.foregroundColor,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  State<_AppActionButton> createState() => _AppActionButtonState();
}

class _AppActionButtonState extends State<_AppActionButton> {
  bool _pressed = false;
  bool _hovered = false;

  BorderRadius _resolveRadius() {
    if (widget.isClassic) return BorderRadius.zero;
    const pill = Radius.circular(20);
    const inner = Radius.circular(8);
    if (_pressed || (widget.isFirst && widget.isLast)) {
      return const BorderRadius.all(pill);
    }
    if (widget.isFirst) {
      return const BorderRadius.horizontal(left: pill, right: inner);
    }
    if (widget.isLast) {
      return const BorderRadius.horizontal(left: inner, right: pill);
    }
    return const BorderRadius.all(inner);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = _resolveRadius();
    final fg = widget.foregroundColor ?? cs.onSurface;
    final baseBg =
        widget.backgroundColor ??
        (widget.outlined ? Colors.transparent : cs.surfaceContainerHighest);
    final overlay = _pressed ? 0.16 : (_hovered ? 0.10 : 0.0);
    final fill = overlay == 0
        ? baseBg
        : (baseBg == Colors.transparent
              ? fg.withValues(alpha: overlay)
              : Color.alphaBlend(fg.withValues(alpha: overlay), baseBg));

    Widget btn = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: widget.height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: widget.outlined
            ? Border.all(color: widget.borderColor ?? cs.outlineVariant)
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.item.onTap,
          onLongPress: widget.item.onLongPress,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onHover: (v) => setState(() => _hovered = v),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.item.label != null ? 12 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  label: Text(widget.item.badge ?? ''),
                  isLabelVisible: widget.item.badge != null,
                  backgroundColor: cs.primary,
                  textColor: cs.onPrimary,
                  child: Icon(widget.item.icon, size: 19, color: fg),
                ),
                if (widget.item.label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.item.label!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.item.tooltip != null) {
      btn = Tooltip(message: widget.item.tooltip!, child: btn);
    }
    return btn;
  }
}

/// Style-aware segmented button group: renders M3 Expressive gapped/morphing
/// pills in [SettingsStyle.expressive], and Material [SegmentedButton] in
/// [SettingsStyle.classic].
class AppButtonGroup<T> extends ConsumerWidget {
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final void Function(Set<T>)? onSelectionChanged;
  final bool expandSegments;
  final double height;

  const AppButtonGroup({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.expandSegments = false,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final isClassic =
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle)) ==
        SettingsStyle.classic;

    if (isClassic) {
      final seg = SegmentedButton<T>(
        segments: segments,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          shape: const StadiumBorder(),
        ),
      );
      return expandSegments
          ? SizedBox(width: double.infinity, child: seg)
          : seg;
    }

    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isSelected = selected.contains(segment.value);
      final isFirst = i == 0;
      final isLast = i == segments.length - 1;

      final pill = _ExpressiveSegmentButton(
        icon: segment.icon,
        label: segment.label,
        isSelected: isSelected,
        isFirst: isFirst,
        isLast: isLast,
        enabled: segment.enabled && onSelectionChanged != null,
        height: height,
        onTap: onSelectionChanged == null || !segment.enabled
            ? null
            : () => onSelectionChanged!({segment.value}),
      );

      if (i > 0) children.add(const SizedBox(width: 3));
      children.add(expandSegments ? Expanded(child: pill) : pill);
    }

    return Row(
      mainAxisSize: expandSegments ? MainAxisSize.max : MainAxisSize.min,
      children: children,
    );
  }
}

class _ExpressiveSegmentButton extends StatefulWidget {
  final Widget? icon;
  final Widget? label;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final bool enabled;
  final double height;
  final VoidCallback? onTap;

  const _ExpressiveSegmentButton({
    this.icon,
    this.label,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.enabled,
    required this.height,
    this.onTap,
  });

  @override
  State<_ExpressiveSegmentButton> createState() =>
      _ExpressiveSegmentButtonState();
}

class _ExpressiveSegmentButtonState extends State<_ExpressiveSegmentButton> {
  bool _pressed = false;
  bool _hovered = false;

  BorderRadius _resolveRadius() {
    const pill = Radius.circular(20);
    const inner = Radius.circular(8);
    if (widget.isSelected || _pressed) {
      return const BorderRadius.all(pill);
    }
    if (widget.isFirst && widget.isLast) {
      return const BorderRadius.all(pill);
    }
    if (widget.isFirst) {
      return const BorderRadius.horizontal(left: pill, right: inner);
    }
    if (widget.isLast) {
      return const BorderRadius.horizontal(left: inner, right: pill);
    }
    return const BorderRadius.all(inner);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = _resolveRadius();

    final baseBg = widget.isSelected
        ? cs.primary
        : cs.surfaceContainerHighest;
    final bg = (_hovered || _pressed) && widget.enabled
        ? Color.alphaBlend(
            (widget.isSelected ? cs.onPrimary : cs.onSurface).withValues(
              alpha: _pressed ? 0.14 : 0.08,
            ),
            baseBg,
          )
        : baseBg;

    final fg = widget.isSelected ? cs.onPrimary : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: widget.height,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onHighlightChanged: widget.enabled
              ? (v) => setState(() => _pressed = v)
              : null,
          onHover: widget.enabled ? (v) => setState(() => _hovered = v) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: IconTheme(
              data: IconThemeData(color: fg, size: 17),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      if (widget.label != null) const SizedBox(width: 6),
                    ],
                    if (widget.label != null) Flexible(child: widget.label!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

