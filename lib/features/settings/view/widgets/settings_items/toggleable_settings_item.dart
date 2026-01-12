import 'package:flutter/material.dart';
import 'base_settings_item.dart';

class ToggleableSettingsItem extends BaseSettingsItem {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleableSettingsItem({
    super.key,
    super.icon,
    super.iconColor,
    required super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.roundness,
    super.isCompact,
    super.trailingWidgets,
    super.layoutType,
    super.focusNode,
    super.autofocus,
    required this.value,
    required this.onChanged,
  }) : super(onTap: null); // Tap handled in build for focus + toggle.

  @override
  Widget build(BuildContext context) {
    return buildWithTap(context, () => onChanged(!value));
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
        if (trailingWidgets == null)
          Transform.scale(
            scale: effectiveCompact ? 0.8 : 1.0,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor ?? accent,
            ),
          )
        else
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
