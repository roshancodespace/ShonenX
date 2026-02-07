import 'package:flutter/material.dart';
import 'base_settings_item.dart';

class ToggleableSettingsItem extends BaseSettingsItem {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleableSettingsItem({
    super.key,
    super.icon,
    super.iconColor,
    super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.isExpressive,
    super.roundness,
    super.containerColor,
    super.isCompact,
    super.trailingWidgets,
    super.layoutType,
    required this.value,
    required this.onChanged,
  }) : super(onTap: null);

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
    
    final effectiveActiveColor = accent ?? colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null || leading != null) ...[
          buildIconContainer(context, effectiveCompact, dimensions),
          SizedBox(width: dimensions.spacing),
        ],
        buildTitleAndDescription(context, effectiveCompact, dimensions),
        if (trailingWidgets == null)
          Transform.scale(
            scale: effectiveCompact ? 0.8 : 0.9,
            alignment: Alignment.centerRight,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: colorScheme.onPrimary,
              activeTrackColor: effectiveActiveColor,
              inactiveThumbColor: colorScheme.outline,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => Colors.transparent,
              ),
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