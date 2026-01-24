import 'package:flutter/material.dart';
import 'base_settings_item.dart';

class DropdownSettingsItem extends BaseSettingsItem {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const DropdownSettingsItem({
    super.key,
    super.icon,
    super.iconColor,
    super.accent,
    required super.title,
    super.description,
    super.leading,
    super.isExpressive,
    super.roundness,
    super.containerColor,
    super.isCompact,
    super.layoutType,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(onTap: null);

  @override
  bool needsVerticalLayoutByContent() => true;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null || leading != null) ...[
            buildIconContainer(context, effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
          ],
          buildTitleAndDescription(context, effectiveCompact, dimensions),
          SizedBox(width: dimensions.spacing),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.4,
              minWidth: 100,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: effectiveCompact ? 8 : 12,
            ),
            decoration: ShapeDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveCompact ? 8 : 12),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: effectiveCompact ? 20 : 24,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                dropdownColor: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                elevation: 1,
                menuMaxHeight: 300,
                itemHeight: effectiveCompact ? 48 : 52,
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildVerticalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             if (icon != null || leading != null) ...[
              buildIconContainer(context, effectiveCompact, dimensions),
              SizedBox(width: dimensions.spacing),
            ],
            buildTitleAndDescription(
              context,
              effectiveCompact,
              dimensions,
              isVertical: true,
            ),
          ],
        ),
        SizedBox(height: effectiveCompact ? 12 : 16),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveCompact ? 8 : 12),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: effectiveCompact ? 12 : 16,
            vertical: effectiveCompact ? 2 : 4,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
                size: effectiveCompact ? 20 : 24,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              dropdownColor: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              elevation: 1,
              menuMaxHeight: 300,
              itemHeight: effectiveCompact ? 48 : 52,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}