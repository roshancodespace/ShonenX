import 'package:flutter/material.dart';
import 'base_settings_item.dart';

class SelectableSettingsItem extends BaseSettingsItem {
  final bool isSelected;
  final bool isInSelectionMode;

  const SelectableSettingsItem({
    super.key,
    super.icon,
    super.iconColor,
    required super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.onTap,
    super.roundness,
    super.isCompact,
    super.trailingWidgets,
    super.layoutType,
    super.focusNode,
    super.autofocus,
    this.isSelected = false,
    this.isInSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool shouldGreyOut = isInSelectionMode && !isSelected;
    return Opacity(
      opacity: shouldGreyOut ? 0.5 : 1.0,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildIconContainer(effectiveCompact, dimensions),
        SizedBox(width: dimensions.spacing),
        buildTitleAndDescription(effectiveCompact, dimensions),
        if (trailingWidgets == null) ...[
          if (isSelected)
            Container(
              width: effectiveCompact ? 20 : 24,
              height: effectiveCompact ? 20 : 24,
              decoration: BoxDecoration(
                color: iconColor ?? accent,
                borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
              ),
              child: Icon(
                Icons.check,
                size: effectiveCompact ? 14 : 16,
                color: Colors.white,
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
