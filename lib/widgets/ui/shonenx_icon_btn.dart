import 'package:flutter/material.dart';

class ShonenXIconButton extends StatelessWidget {
  // Required properties
  final IconData icon;
  final VoidCallback? onPressed;

  // Optional properties with defaults
  final String? tooltip;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double iconSize;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final TextStyle? labelStyle;
  final double? labelSpacing;
  final bool showDisabledOverlay;
  final double disabledAlpha;
  final Widget? badgeContent;
  final Axis labelDirection;
  final bool useMaterial3;

  const ShonenXIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = 20,
    this.width,
    this.height = 36,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius,
    this.labelStyle,
    this.labelSpacing = 8.0,
    this.showDisabledOverlay = true,
    this.disabledAlpha = 0.5,
    this.badgeContent,
    this.labelDirection = Axis.horizontal,
    this.useMaterial3 = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = onPressed != null;

    // Use theme colors by default, with fallback to provided colors
    final activeBackgroundColor = backgroundColor ??
        (useMaterial3
            ? colorScheme.primaryContainer
            : colorScheme.primary.withValues(alpha: 0.12));

    final activeForegroundColor = foregroundColor ??
        (useMaterial3 ? colorScheme.onPrimaryContainer : colorScheme.primary);

    // Calculate alpha values for disabled state
    final disabledBackgroundColor = showDisabledOverlay
        ? activeBackgroundColor.withValues(alpha: disabledAlpha)
        : activeBackgroundColor;

    final disabledForegroundColor = showDisabledOverlay
        ? activeForegroundColor.withValues(alpha: disabledAlpha)
        : activeForegroundColor;

    // Default label style if not provided
    final effectiveLabelStyle = labelStyle ??
        (useMaterial3 ? theme.textTheme.labelLarge : theme.textTheme.bodyMedium)
            ?.copyWith(
          color: isEnabled ? activeForegroundColor : disabledForegroundColor,
          fontWeight: FontWeight.w500,
        );

    // Create a widget for the content
    Widget content = Icon(icon, size: iconSize);

    // Add label if provided
    if (label != null) {
      final labelWidget = Text(
        label!,
        style: effectiveLabelStyle,
        overflow: TextOverflow.ellipsis,
      );

      if (labelDirection == Axis.horizontal) {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            content,
            SizedBox(width: labelSpacing),
            labelWidget,
          ],
        );
      } else {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            content,
            SizedBox(height: labelSpacing),
            labelWidget,
          ],
        );
      }
    }

    // Use theme's border radius or custom one
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(useMaterial3 ? 8 : 4);

    // Create the button widget
    Widget buttonWidget = Material(
      color: isEnabled ? activeBackgroundColor : disabledBackgroundColor,
      borderRadius: effectiveBorderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: effectiveBorderRadius,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          child: Center(child: content),
        ),
      ),
    );

    // Add badge if provided
    if (badgeContent != null) {
      buttonWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          buttonWidget,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                child: badgeContent!,
              ),
            ),
          ),
        ],
      );
    }

    // Add tooltip if provided
    if (tooltip != null) {
      buttonWidget = Tooltip(
        message: tooltip!,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
