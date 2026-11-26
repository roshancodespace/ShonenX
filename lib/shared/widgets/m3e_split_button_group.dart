import 'package:material_ui/material_ui.dart';

/// Material 3 Expressive connected/split button group with animated corner
/// morphing on selection and press, plus responsive width handling.
class M3eSplitButtonGroup<T> extends StatelessWidget {
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final void Function(Set<T>)? onSelectionChanged;
  final bool expandSegments;
  final double height;

  const M3eSplitButtonGroup({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.expandSegments = false,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isSelected = selected.contains(segment.value);
      final isFirst = i == 0;
      final isLast = i == segments.length - 1;

      final pill = _M3eSegmentButton(
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

class _M3eSegmentButton extends StatefulWidget {
  final Widget? icon;
  final Widget? label;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final bool enabled;
  final double height;
  final VoidCallback? onTap;

  const _M3eSegmentButton({
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
  State<_M3eSegmentButton> createState() => _M3eSegmentButtonState();
}

class _M3eSegmentButtonState extends State<_M3eSegmentButton> {
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

