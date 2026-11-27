import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

enum AppButtonVariant { primary, tonal, outlined, text, destructive }

enum AppButtonSize { small, medium, large }

class AppButton extends ConsumerStatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.borderRadius,
  });

  @override
  ConsumerState<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends ConsumerState<AppButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final (height, hPad, fontSize, iconSize) = switch (widget.size) {
      AppButtonSize.small => (34.0, 12.0, 12.5, 15.0),
      AppButtonSize.medium => (44.0, 18.0, 14.0, 18.0),
      AppButtonSize.large => (52.0, 24.0, 15.0, 20.0),
    };

    final (baseBg, fg, borderColor) = switch (widget.variant) {
      AppButtonVariant.primary => (cs.primary, cs.onPrimary, null),
      AppButtonVariant.tonal => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        null,
      ),
      AppButtonVariant.outlined => (
        Colors.transparent,
        cs.primary,
        cs.outlineVariant,
      ),
      AppButtonVariant.text => (Colors.transparent, cs.primary, null),
      AppButtonVariant.destructive => (
        isClassic ? cs.error : cs.errorContainer,
        isClassic ? cs.onError : cs.onErrorContainer,
        null,
      ),
    };

    final effectiveBg = enabled
        ? baseBg
        : (baseBg == Colors.transparent
              ? Colors.transparent
              : cs.onSurface.withValues(alpha: 0.12));
    final effectiveFg = enabled ? fg : cs.onSurface.withValues(alpha: 0.38);

    final overlayAlpha = _pressed ? 0.14 : (_hovered ? 0.08 : 0.0);
    final fill = overlayAlpha == 0
        ? effectiveBg
        : (effectiveBg == Colors.transparent
              ? effectiveFg.withValues(alpha: overlayAlpha)
              : Color.alphaBlend(
                  effectiveFg.withValues(alpha: overlayAlpha),
                  effectiveBg,
                ));

    final radius =
        widget.borderRadius ?? (isClassic ? 10.0 : (_pressed ? 14.0 : 999.0));

    final leadingWidget = widget.isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 2, color: effectiveFg),
          )
        : (widget.leading ??
              (widget.icon != null
                  ? Icon(widget.icon, size: iconSize, color: effectiveFg)
                  : null));

    final content = AnimatedScale(
      scale: (!isClassic && _pressed && enabled) ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: borderColor != null
              ? Border.all(
                  color: enabled
                      ? borderColor
                      : cs.onSurface.withValues(alpha: 0.12),
                )
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(radius),
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onHighlightChanged: enabled
                ? (v) => setState(() => _pressed = v)
                : null,
            onHover: enabled ? (v) => setState(() => _hovered = v) : null,
            child: Row(
              mainAxisSize: widget.isExpanded
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingWidget != null) ...[
                  leadingWidget,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: effectiveFg,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 6),
                  IconTheme(
                    data: IconThemeData(color: effectiveFg, size: iconSize),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return widget.isExpanded
        ? SizedBox(width: double.infinity, child: content)
        : content;
  }
}
