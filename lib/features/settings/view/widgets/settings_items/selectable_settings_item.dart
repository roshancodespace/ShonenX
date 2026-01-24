import 'package:flutter/material.dart';
import 'base_settings_item.dart';

class SelectableSettingsItem extends BaseSettingsItem {
  final bool isSelected;
  final bool isInSelectionMode;

  const SelectableSettingsItem({
    super.key,
    super.icon,
    super.iconColor,
    super.accent,
    required super.title,
    super.description,
    super.leading,
    super.onTap,
    super.isExpressive,
    super.roundness,
    super.containerColor,
    super.isCompact,
    super.trailingWidgets,
    super.layoutType,
    this.isSelected = false,
    this.isInSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool shouldGreyOut = isInSelectionMode && !isSelected;
    return Opacity(
      opacity: shouldGreyOut ? 0.38 : 1.0, 
      child: super.build(context),
    );
  }

  @override
  bool needsVerticalLayoutByContent() => false;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final activeColor = iconColor ?? accent ?? colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null || leading != null) ...[
          buildIconContainer(context, effectiveCompact, dimensions),
          SizedBox(width: dimensions.spacing),
        ],
        buildTitleAndDescription(context, effectiveCompact, dimensions),
        if (trailingWidgets == null) ...[
          if (isSelected)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: effectiveCompact ? 24 : 28,
              height: effectiveCompact ? 24 : 28,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: effectiveCompact ? 16 : 18,
                color: colorScheme.onPrimary,
              ),
            )
        ] else
          ...buildCustomTrailingWidgets(effectiveCompact),
      ],
    );
  }

  @override
  Widget buildVerticalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    return buildHorizontalLayout(context, effectiveCompact, dimensions);
  }
}