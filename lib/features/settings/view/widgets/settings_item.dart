import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum SettingsItemType {
  normal,
  selectable,
  toggleable,
  slider,
  dropdown,
  segmentedToggle,
}

enum SettingsItemLayout {
  auto, // Automatically chooses based on screen size and content
  horizontal, // Forces horizontal layout
  vertical, // Forces vertical layout
}

class SettingsItem extends StatelessWidget {
  final Widget? leading;
  final Icon? icon;
  final Color? iconColor;
  final Color accent;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final double roundness;

  // Selection mode properties
  final SettingsItemType type;
  final bool isSelected;
  final bool isInSelectionMode;

  // Toggle properties
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;

  // Slider properties
  final double? sliderValue;
  final double? sliderMin;
  final double? sliderMax;
  final int? sliderDivisions;
  final String? sliderSuffix;
  final ValueChanged<double>? onSliderChanged;

  // Dropdown properties
  final String? dropdownValue;
  final List<String>? dropdownItems;
  final ValueChanged<String?>? onDropdownChanged;

  // Segmented toggle properties
  final int? segmentedSelectedIndex;
  final List<Widget>? segmentedOptions;
  final List<String>? segmentedLabels;
  final ValueChanged<int>? onSegmentedChanged;

  // Responsive and compact mode properties
  final bool isCompact;

  // New trailing widgets property
  final List<Widget>? trailingWidgets;

  // Layout property
  final SettingsItemLayout layoutType;

  const SettingsItem({
    super.key,
    this.icon,
    this.iconColor,
    required this.accent,
    required this.title,
    required this.description,
    this.leading,
    this.onTap,
    this.roundness = 12,
    this.type = SettingsItemType.normal,
    this.isSelected = false,
    this.isInSelectionMode = false,
    this.toggleValue,
    this.onToggleChanged,
    this.sliderValue,
    this.sliderMin,
    this.sliderMax,
    this.sliderDivisions,
    this.sliderSuffix,
    this.onSliderChanged,
    this.dropdownValue,
    this.dropdownItems,
    this.onDropdownChanged,
    this.segmentedSelectedIndex,
    this.segmentedOptions,
    this.segmentedLabels,
    this.onSegmentedChanged,
    this.isCompact = false,
    this.trailingWidgets,
    this.layoutType = SettingsItemLayout.auto, // New parameter
  });

  @override
  Widget build(BuildContext context) {
    final bool shouldGreyOut =
        type == SettingsItemType.selectable && isInSelectionMode && !isSelected;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final effectiveCompact = isCompact || isSmallScreen;

    final dimensions =
        _getResponsiveDimensions(effectiveCompact, isSmallScreen);

    return Opacity(
      opacity: shouldGreyOut ? 0.5 : 1.0,
      child: Card(
        elevation: effectiveCompact ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundness),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(roundness),
          child: InkWell(
            onTap: _shouldDisableOnTap() ? null : onTap,
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
      ),
    );
  }

  bool _shouldDisableOnTap() {
    return type == SettingsItemType.toggleable ||
        type == SettingsItemType.slider ||
        type == SettingsItemType.dropdown ||
        type == SettingsItemType.segmentedToggle;
  }

  Widget _buildLayout(
    BuildContext context,
    bool effectiveCompact,
    bool isSmallScreen,
    ResponsiveDimensions dimensions,
  ) {
    // Determine layout based on the layoutType parameter
    final bool useVerticalLayout = _shouldUseVerticalLayout(
      isSmallScreen,
      effectiveCompact,
    );

    if (useVerticalLayout) {
      return _buildVerticalLayout(context, effectiveCompact, dimensions);
    }
    return _buildHorizontalLayout(context, effectiveCompact, dimensions);
  }

  bool _shouldUseVerticalLayout(bool isSmallScreen, bool effectiveCompact) {
    // Respect the explicit layout choice if not auto
    switch (layoutType) {
      case SettingsItemLayout.horizontal:
        return false;
      case SettingsItemLayout.vertical:
        return true;
      case SettingsItemLayout.auto:
      default:
        // Auto behavior - use vertical layout for complex controls on small screens
        return isSmallScreen && _needsVerticalLayoutByContent();
    }
  }

  bool _needsVerticalLayoutByContent() {
    return type == SettingsItemType.dropdown ||
        type == SettingsItemType.slider ||
        type == SettingsItemType.segmentedToggle;
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    if (type == SettingsItemType.dropdown) {
      return _buildHorizontalDropdownLayout(
          context, effectiveCompact, dimensions);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconContainer(effectiveCompact, dimensions),
        SizedBox(width: dimensions.spacing),
        _buildTitleAndDescription(effectiveCompact, dimensions),
        if (_shouldShowDefaultTrailing())
          _buildDefaultTrailingWidget(effectiveCompact),
        if (trailingWidgets != null)
          ..._buildCustomTrailingWidgets(effectiveCompact),
      ],
    );
  }

  Widget _buildHorizontalDropdownLayout(
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
          _buildIconContainer(effectiveCompact, dimensions),
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
                value: dropdownValue,
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
                items: dropdownItems?.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: effectiveCompact ? 8 : 12,
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: effectiveCompact ? 14 : 15,
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onDropdownChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCustomTrailingWidgets(bool effectiveCompact) {
    return trailingWidgets!.map((widget) {
      return Padding(
        padding: EdgeInsets.only(left: effectiveCompact ? 8 : 12),
        child: widget,
      );
    }).toList();
  }

  Widget _buildVerticalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    if (type == SettingsItemType.dropdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconContainer(effectiveCompact, dimensions),
              SizedBox(width: dimensions.spacing),
              _buildTitleAndDescription(effectiveCompact, dimensions,
                  isVertical: true),
            ],
          ),
          SizedBox(height: effectiveCompact ? 8 : 12),
          _buildDropdown(context, effectiveCompact),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIconContainer(effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
            _buildTitleAndDescription(effectiveCompact, dimensions,
                isVertical: true),
            const Spacer(),
            if (_shouldShowDefaultTrailing())
              _buildDefaultTrailingWidget(effectiveCompact),
            if (trailingWidgets != null)
              ..._buildCustomTrailingWidgets(effectiveCompact),
          ],
        ),
        if (type == SettingsItemType.segmentedToggle) ...[
          SizedBox(height: effectiveCompact ? 8 : 12),
          _buildSegmentedToggle(context, effectiveCompact),
        ],
        if (type == SettingsItemType.slider) ...[
          SizedBox(height: effectiveCompact ? 8 : 12),
          _buildSlider(context, effectiveCompact),
        ]
      ],
    );
  }

  Widget _buildIconContainer(
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

  Widget _buildTitleAndDescription(
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

  Widget _buildSegmentedToggle(BuildContext context, bool effectiveCompact) {
    if (segmentedOptions == null ||
        segmentedLabels == null ||
        segmentedOptions!.length != 3) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = segmentedSelectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSegmentedChanged?.call(index),
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
                      child: segmentedOptions![index],
                    ),
                    if (!effectiveCompact) ...[
                      const SizedBox(width: 6),
                      Text(
                        segmentedLabels![index],
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
        }),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, bool effectiveCompact) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
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
          value: dropdownValue,
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
          selectedItemBuilder: (BuildContext context) {
            return dropdownItems?.map<Widget>((String item) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: effectiveCompact ? 14 : 15,
                        color: (iconColor ?? accent),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList() ??
                [];
          },
          items: dropdownItems?.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: effectiveCompact ? 8 : 12,
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: effectiveCompact ? 14 : 15,
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: onDropdownChanged,
        ),
      ),
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
              value: sliderValue ?? 0,
              min: sliderMin ?? 0,
              max: sliderMax ?? 100,
              divisions: sliderDivisions,
              onChanged: onSliderChanged,
            ),
          ),
        ),
        SizedBox(width: effectiveCompact ? 6 : 8),
        Text(
          '${(sliderValue ?? 0).toStringAsFixed(sliderDivisions != null ? 0 : 1)}${sliderSuffix ?? ''}',
          style: TextStyle(
            fontSize: effectiveCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: accent,
          ),
        ),
      ],
    );
  }

  bool _shouldShowDefaultTrailing() {
    return trailingWidgets == null &&
        type != SettingsItemType.slider &&
        type != SettingsItemType.dropdown &&
        type != SettingsItemType.segmentedToggle;
  }

  Widget _buildDefaultTrailingWidget(bool effectiveCompact) {
    switch (type) {
      case SettingsItemType.selectable:
        if (isSelected) {
          return Container(
            width: effectiveCompact ? 20 : 24,
            height: effectiveCompact ? 20 : 24,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
            ),
            child: Icon(
              Icons.check,
              size: effectiveCompact ? 14 : 16,
              color: Colors.white,
            ),
          );
        } else {
          return const SizedBox.shrink();
        }

      case SettingsItemType.toggleable:
        return Transform.scale(
          scale: effectiveCompact ? 0.8 : 1.0,
          child: Switch(
            value: toggleValue ?? false,
            onChanged: onToggleChanged,
            activeColor: iconColor,
          ),
        );

      case SettingsItemType.normal:
      default:
        return Icon(
          Iconsax.arrow_right_3,
          size: effectiveCompact ? 16 : 20,
          color: Colors.grey[400],
        );
    }
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