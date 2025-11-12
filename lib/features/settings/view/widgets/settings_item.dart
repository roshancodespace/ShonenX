import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum SettingsItemLayout {
  auto,
  horizontal,
  vertical,
}

abstract class BaseSettingsItem extends StatelessWidget {
  final Widget? leading;
  final Icon? icon;
  final Color? iconColor;
  final Color accent;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final double roundness;
  final bool isCompact;
  final List<Widget>? trailingWidgets;
  final SettingsItemLayout layoutType;

  const BaseSettingsItem({
    super.key,
    this.icon,
    this.iconColor,
    required this.accent,
    required this.title,
    required this.description,
    this.leading,
    this.onTap,
    this.roundness = 12,
    this.isCompact = false,
    this.trailingWidgets,
    this.layoutType = SettingsItemLayout.auto,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final effectiveCompact = isCompact || isSmallScreen;

    final dimensions =
        _getResponsiveDimensions(effectiveCompact, isSmallScreen);

    return Card(
      elevation: effectiveCompact ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(roundness),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(roundness),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(roundness),
          child: Padding(
            padding: dimensions.padding,
            child: _buildLayout(
              context,
              effectiveCompact,
              isSmallScreen,
              dimensions,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    bool effectiveCompact,
    bool isSmallScreen,
    ResponsiveDimensions dimensions,
  ) {
    final bool useVerticalLayout = _shouldUseVerticalLayout(
      isSmallScreen,
    );

    if (useVerticalLayout) {
      return buildVerticalLayout(context, effectiveCompact, dimensions);
    }
    return buildHorizontalLayout(context, effectiveCompact, dimensions);
  }

  bool _shouldUseVerticalLayout(bool isSmallScreen) {
    switch (layoutType) {
      case SettingsItemLayout.horizontal:
        return false;
      case SettingsItemLayout.vertical:
        return true;
      case SettingsItemLayout.auto:
      default:
        return isSmallScreen && needsVerticalLayoutByContent();
    }
  }

  bool needsVerticalLayoutByContent();

  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  );

  Widget buildVerticalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  );

  Widget buildIconContainer(
      bool effectiveCompact, ResponsiveDimensions dimensions) {
    return Container(
      width: dimensions.iconContainerSize,
      height: dimensions.iconContainerSize,
      decoration: BoxDecoration(
        color: (iconColor ?? accent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(effectiveCompact ? 6 : 8),
      ),
      child: Center(
        child: (icon != null)
            ? IconTheme(
                data: IconThemeData(
                  color: (iconColor ?? accent),
                  size: dimensions.iconSize,
                ),
                child: icon!,
              )
            : (leading != null)
                ? leading
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget buildTitleAndDescription(
    bool effectiveCompact,
    ResponsiveDimensions dimensions, {
    bool isVertical = false,
  }) {
    return Expanded(
      flex: isVertical ? 0 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: dimensions.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: (effectiveCompact || isVertical) ? 1 : 2,
          ),
          if (description.isNotEmpty &&
              (!effectiveCompact || description.isNotEmpty)) ...[
            SizedBox(height: effectiveCompact ? 1 : 2),
            Text(
              description,
              style: TextStyle(
                fontSize: dimensions.descriptionFontSize,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: (effectiveCompact || isVertical) ? 1 : 2,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> buildCustomTrailingWidgets(bool effectiveCompact) {
    if (trailingWidgets == null) return [];
    return trailingWidgets!.map((widget) {
      return Padding(
        padding: EdgeInsets.only(left: effectiveCompact ? 8 : 12),
        child: widget,
      );
    }).toList();
  }

  ResponsiveDimensions _getResponsiveDimensions(
      bool effectiveCompact, bool isSmallScreen) {
    return ResponsiveDimensions(
      iconSize: effectiveCompact ? 20 : (isSmallScreen ? 22 : 24),
      iconContainerSize: effectiveCompact ? 40 : (isSmallScreen ? 44 : 48),
      titleFontSize: effectiveCompact ? 14 : (isSmallScreen ? 15 : 16),
      descriptionFontSize: effectiveCompact ? 11 : (isSmallScreen ? 11.5 : 12),
      padding: effectiveCompact
          ? const EdgeInsets.all(12.0)
          : (isSmallScreen
              ? const EdgeInsets.all(14.0)
              : const EdgeInsets.all(16.0)),
      spacing: effectiveCompact ? 12 : (isSmallScreen ? 14 : 16),
    );
  }
}

class ResponsiveDimensions {
  final double iconSize;
  final double iconContainerSize;
  final double titleFontSize;
  final double descriptionFontSize;
  final EdgeInsets padding;
  final double spacing;

  const ResponsiveDimensions({
    required this.iconSize,
    required this.iconContainerSize,
    required this.titleFontSize,
    required this.descriptionFontSize,
    required this.padding,
    required this.spacing,
  });
}

// --- Normal Settings Item ---
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
    // A normal item doesn't typically need a vertical layout,
    // so we default to the horizontal one.
    return buildHorizontalLayout(context, effectiveCompact, dimensions);
  }
}

// --- Selectable Settings Item ---
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
                borderRadius:
                    BorderRadius.circular(effectiveCompact ? 10 : 12),
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

// --- Toggleable Settings Item ---
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
    required this.value,
    required this.onChanged,
  }) : super(onTap: null); // Disable onTap

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

// --- Slider Settings Item ---
class SliderSettingsItem extends BaseSettingsItem {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? suffix;

  const SliderSettingsItem({
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
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.suffix,
  }) : super(onTap: null); // Disable onTap

  @override
  bool needsVerticalLayoutByContent() => true;

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
        SizedBox(width: dimensions.spacing),
        Expanded(
          flex: 2,
          child: _buildSlider(context, effectiveCompact),
        ),
      ],
    );
  }

  @override
  Widget buildVerticalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
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
        _buildSlider(context, effectiveCompact),
      ],
    );
  }

  Widget _buildSlider(BuildContext context, bool effectiveCompact) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: accent.withOpacity(0.3),
              thumbColor: accent,
              overlayColor: accent.withOpacity(0.2),
              trackHeight: effectiveCompact ? 2 : 3,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: effectiveCompact ? 6 : 8,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: effectiveCompact ? 12 : 16,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(width: effectiveCompact ? 6 : 8),
        Text(
          '${(value).toStringAsFixed(divisions != null ? 0 : 1)}${suffix ?? ''}',
          style: TextStyle(
            fontSize: effectiveCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: accent,
          ),
        ),
      ],
    );
  }
}

// --- Dropdown Settings Item ---
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
                style: TextStyle(
                  fontSize: effectiveCompact ? 14 : 15,
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius:
                    BorderRadius.circular(effectiveCompact ? 10 : 12),
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
              style: TextStyle(
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

// --- Segmented Toggle Settings Item ---
class SegmentedToggleSettingsItem<T> extends BaseSettingsItem {
  final T selectedValue;
  final Map<T, Widget> children;
  final ValueChanged<int> onValueChanged;
  final Map<T, String>? labels;

  const SegmentedToggleSettingsItem({
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
    required this.selectedValue,
    required this.children,
    required this.onValueChanged,
    this.labels,
  })  : assert(children.length > 1, "There must be at least 2 children."),
        super(onTap: null);

  @override
  bool needsVerticalLayoutByContent() => true;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    return Row(
      children: [
        buildIconContainer(effectiveCompact, dimensions),
        SizedBox(width: dimensions.spacing),
        buildTitleAndDescription(effectiveCompact, dimensions),
        SizedBox(width: dimensions.spacing),
        Expanded(
          flex: 2,
          child: _buildSegmentedToggle(context, effectiveCompact),
        ),
      ],
    );
  }

  @override
  Widget buildVerticalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
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
        _buildSegmentedToggle(context, effectiveCompact),
      ],
    );
  }

  Widget _buildSegmentedToggle(BuildContext context, bool effectiveCompact) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
      ),
      child: Row(
        children: children.keys.map((key) {
          final isSelected = selectedValue == key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onValueChanged(key as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(2),
                padding: EdgeInsets.symmetric(
                  vertical: effectiveCompact ? 8 : 10,
                  horizontal: effectiveCompact ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? (iconColor ?? accent) : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(effectiveCompact ? 8 : 10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color:
                            isSelected ? Colors.white : (iconColor ?? accent),
                        size: effectiveCompact ? 16 : 18,
                      ),
                      child: children[key]!,
                    ),
                    if (!effectiveCompact && labels != null && labels![key] != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        labels![key]!,
                        style: TextStyle(
                          fontSize: effectiveCompact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : (iconColor ?? accent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}