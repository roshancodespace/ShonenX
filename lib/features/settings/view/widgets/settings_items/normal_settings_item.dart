import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'base_settings_item.dart';

class NormalSettingsItem extends BaseSettingsItem {
  const NormalSettingsItem({
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
  });

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
          Icon(
            Iconsax.arrow_right_3,
            size: effectiveCompact ? 16 : 20,
            color: Colors.grey[400],
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
