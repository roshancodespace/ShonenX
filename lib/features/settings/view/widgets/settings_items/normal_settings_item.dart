import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'base_settings_item.dart';

class NormalSettingsItem extends BaseSettingsItem {
  const NormalSettingsItem({
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
  });

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null || leading != null) ...[
          buildIconContainer(context, effectiveCompact, dimensions),
          SizedBox(width: dimensions.spacing),
        ],
        buildTitleAndDescription(context, effectiveCompact, dimensions),
        if (trailingWidgets == null)
          Icon(
            Iconsax.arrow_right_3,
            size: effectiveCompact ? 16 : 20,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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