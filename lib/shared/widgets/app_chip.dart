import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class AppChip extends ConsumerStatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? avatar;
  final bool? selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onTap;
  final bool showCheckmark;
  final String? tooltip;
  final bool enabled;
  final EdgeInsetsGeometry? padding;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.avatar,
    this.selected,
    this.onSelected,
    this.onTap,
    this.showCheckmark = true,
    this.tooltip,
    this.enabled = true,
    this.padding,
  });

  @override
  ConsumerState<AppChip> createState() => _AppChipState();
}

class _AppChipState extends ConsumerState<AppChip> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isClassic =
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle)) ==
        SettingsStyle.classic;

    final isFilter = widget.selected != null;
    final isSelected = widget.selected ?? false;
    final interactive =
        widget.enabled && (widget.onSelected != null || widget.onTap != null);

    final bg = isSelected
        ? cs.primaryContainer
        : (_hovered ? cs.surfaceContainerHighest : cs.surfaceContainerLow);

    final fg = isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final iconColor = isSelected ? cs.onPrimaryContainer : cs.primary;

    final borderColor = isSelected
        ? cs.primary.withValues(alpha: isClassic ? 0.8 : 0.45)
        : cs.outlineVariant.withValues(alpha: 0.45);

    final radius = isClassic
        ? BorderRadius.circular(8)
        : BorderRadius.circular(_pressed ? 8 : (isSelected ? 10 : 999));

    Widget? leading = widget.avatar;
    if (leading == null) {
      if (isFilter && isSelected && widget.showCheckmark) {
        leading = Icon(Icons.check_rounded, size: 16, color: iconColor);
      } else if (widget.icon != null) {
        leading = Icon(widget.icon, size: 16, color: iconColor);
      }
    }

    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.enabled ? bg : bg.withValues(alpha: 0.5),
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: interactive
              ? () {
                  if (widget.onSelected != null) {
                    widget.onSelected!(!isSelected);
                  } else {
                    widget.onTap?.call();
                  }
                }
              : null,
          borderRadius: radius,
          splashFactory: isClassic ? null : NoSplash.splashFactory,
          overlayColor: isClassic
              ? null
              : const WidgetStatePropertyAll(Colors.transparent),
          onHighlightChanged: interactive
              ? (v) => setState(() => _pressed = v)
              : null,
          onHover: interactive ? (v) => setState(() => _hovered = v) : null,
          child: Padding(
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 6)],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: widget.enabled ? fg : fg.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      chip = Tooltip(message: widget.tooltip!, child: chip);
    }

    return chip;
  }
}

/// Groups [AppChip] widgets in a responsive [Wrap], optionally inside a styled
/// container card with an optional section [title].
class AppChipGroup extends ConsumerWidget {
  final List<Widget> children;
  final String? title;
  final bool grouped;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  const AppChipGroup({
    super.key,
    required this.children,
    this.title,
    this.grouped = false,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (children.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isClassic =
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle)) ==
        SettingsStyle.classic;

    final wrap = Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
        ],
        wrap,
      ],
    );

    if (!grouped) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(isClassic ? 10 : 20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: content,
    );
  }
}
