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
    required super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.roundness,
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildIconContainer(effectiveCompact, dimensions),
          SizedBox(width: dimensions.spacing),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: dimensions.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: effectiveCompact ? 1 : 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: dimensions.descriptionFontSize,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: dimensions.spacing),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,
              minWidth: 100,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: effectiveCompact ? 8 : 12,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: (iconColor ?? accent).withOpacity(0.8),
                  size: effectiveCompact ? 20 : 24,
                ),
                style: theme.dropdownMenuTheme.textStyle?.copyWith(
                  fontSize: effectiveCompact ? 14 : 15,
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
                elevation: 2,
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            buildIconContainer(effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
            buildTitleAndDescription(effectiveCompact, dimensions,
                isVertical: true),
          ],
        ),
        SizedBox(height: effectiveCompact ? 8 : 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[850]?.withOpacity(0.5)
                : Colors.grey[100]?.withOpacity(0.7),
            borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : accent.withOpacity(0.2),
              width: 1,
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
                color: (iconColor ?? accent).withOpacity(0.8),
                size: effectiveCompact ? 20 : 24,
              ),
              style: theme.dropdownMenuTheme.textStyle?.copyWith(
                fontSize: effectiveCompact ? 14 : 15,
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
              elevation: 2,
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
