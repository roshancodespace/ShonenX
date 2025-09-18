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
  auto,
  horizontal,
  vertical,
}

class SettingsItem extends StatefulWidget {
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
    this.roundness = 16,
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
    this.layoutType = SettingsItemLayout.auto,
  });

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldGreyOut = widget.type == SettingsItemType.selectable &&
        widget.isInSelectionMode &&
        !widget.isSelected;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final effectiveCompact = widget.isCompact || isSmallScreen;

    final dimensions = _getResponsiveDimensions(effectiveCompact, isSmallScreen);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _tapController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: shouldGreyOut ? 0.4 : 1.0,
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: effectiveCompact ? 3 : 4,
                horizontal: effectiveCompact ? 2 : 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.roundness),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 8 + _elevationAnimation.value,
                    offset: Offset(0, 2 + _elevationAnimation.value / 2),
                    spreadRadius: -2,
                  ),
                  if (_isHovered)
                    BoxShadow(
                      color: widget.accent.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: Material(
                color: isDarkMode
                    ? Colors.grey[900]?.withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(widget.roundness),
                child: InkWell(
                  onTap: _shouldDisableOnTap() ? null : widget.onTap,
                  onTapDown: (_) => _tapController.forward(),
                  onTapUp: (_) => _tapController.reverse(),
                  onTapCancel: () => _tapController.reverse(),
                  borderRadius: BorderRadius.circular(widget.roundness),
                  splashColor: widget.accent.withOpacity(0.1),
                  highlightColor: widget.accent.withOpacity(0.05),
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() => _isHovered = true);
                      _hoverController.forward();
                    },
                    onExit: (_) {
                      setState(() => _isHovered = false);
                      _hoverController.reverse();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.roundness),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                          width: 0.5,
                        ),
                        gradient: _isHovered
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  widget.accent.withOpacity(0.03),
                                  widget.accent.withOpacity(0.01),
                                ],
                              )
                            : null,
                      ),
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
            ),
          ),
        );
      },
    );
  }

  bool _shouldDisableOnTap() {
    return widget.type == SettingsItemType.toggleable ||
        widget.type == SettingsItemType.slider ||
        widget.type == SettingsItemType.dropdown ||
        widget.type == SettingsItemType.segmentedToggle;
  }

  Widget _buildLayout(
    BuildContext context,
    bool effectiveCompact,
    bool isSmallScreen,
    ResponsiveDimensions dimensions,
  ) {
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
    switch (widget.layoutType) {
      case SettingsItemLayout.horizontal:
        return false;
      case SettingsItemLayout.vertical:
        return true;
      case SettingsItemLayout.auto:
      default:
        return isSmallScreen && _needsVerticalLayoutByContent();
    }
  }

  bool _needsVerticalLayoutByContent() {
    return widget.type == SettingsItemType.dropdown ||
        widget.type == SettingsItemType.slider ||
        widget.type == SettingsItemType.segmentedToggle;
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    if (widget.type == SettingsItemType.dropdown) {
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
        if (widget.trailingWidgets != null)
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
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: dimensions.titleFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (widget.description.isNotEmpty) ...[
                  SizedBox(height: effectiveCompact ? 2 : 4),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: dimensions.descriptionFontSize,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: dimensions.spacing),
          _buildEnhancedDropdown(context, effectiveCompact, isInline: true),
        ],
      ),
    );
  }

  List<Widget> _buildCustomTrailingWidgets(bool effectiveCompact) {
    return widget.trailingWidgets!.map((widget) {
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
            if (widget.trailingWidgets != null)
              ..._buildCustomTrailingWidgets(effectiveCompact),
          ],
        ),
        if (widget.type == SettingsItemType.dropdown) ...[
          SizedBox(height: effectiveCompact ? 12 : 16),
          _buildEnhancedDropdown(context, effectiveCompact),
        ],
        if (widget.type == SettingsItemType.segmentedToggle) ...[
          SizedBox(height: effectiveCompact ? 12 : 16),
          _buildEnhancedSegmentedToggle(context, effectiveCompact),
        ],
        if (widget.type == SettingsItemType.slider) ...[
          SizedBox(height: effectiveCompact ? 12 : 16),
          _buildEnhancedSlider(context, effectiveCompact),
        ]
      ],
    );
  }

  Widget _buildIconContainer(
      bool effectiveCompact, ResponsiveDimensions dimensions) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: dimensions.iconContainerSize,
      height: dimensions.iconContainerSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (widget.iconColor ?? widget.accent).withOpacity(0.15),
            (widget.iconColor ?? widget.accent).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
        border: Border.all(
          color: (widget.iconColor ?? widget.accent).withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : (widget.iconColor ?? widget.accent).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: (widget.icon != null)
            ? IconTheme(
                data: IconThemeData(
                  color: (widget.iconColor ?? widget.accent),
                  size: dimensions.iconSize,
                ),
                child: widget.icon!,
              )
            : (widget.leading != null)
                ? widget.leading
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTitleAndDescription(
    bool effectiveCompact,
    ResponsiveDimensions dimensions, {
    bool isVertical = false,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      flex: isVertical ? 0 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: dimensions.titleFontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: (effectiveCompact || isVertical) ? 1 : 2,
          ),
          if (widget.description.isNotEmpty) ...[
            SizedBox(height: effectiveCompact ? 2 : 4),
            Text(
              widget.description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: dimensions.descriptionFontSize,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                height: 1.3,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: (effectiveCompact || isVertical) ? 1 : 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedSegmentedToggle(BuildContext context, bool effectiveCompact) {
    if (widget.segmentedOptions == null ||
        widget.segmentedLabels == null ||
        widget.segmentedOptions!.length != 3) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[850]?.withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(effectiveCompact ? 12 : 14),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = widget.segmentedSelectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onSegmentedChanged?.call(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.symmetric(
                  vertical: effectiveCompact ? 10 : 12,
                  horizontal: effectiveCompact ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.iconColor ?? widget.accent)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(effectiveCompact ? 8 : 10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (widget.iconColor ?? widget.accent)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: -1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: IconTheme(
                        data: IconThemeData(
                          color: isSelected
                              ? Colors.white
                              : (widget.iconColor ?? widget.accent)
                                  .withOpacity(0.7),
                          size: effectiveCompact ? 16 : 18,
                        ),
                        child: widget.segmentedOptions![index],
                      ),
                    ),
                    if (!effectiveCompact) ...[
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: effectiveCompact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (widget.iconColor ?? widget.accent)
                                  .withOpacity(0.7),
                        ),
                        child: Text(widget.segmentedLabels![index]),
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

  Widget _buildEnhancedDropdown(BuildContext context, bool effectiveCompact,
      {bool isInline = false}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: isInline ? null : double.infinity,
      constraints: isInline
          ? BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,
              minWidth: 120,
            )
          : null,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[850]?.withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(effectiveCompact ? 12 : 14),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: effectiveCompact ? 14 : 16,
        vertical: effectiveCompact ? 4 : 6,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.dropdownValue,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: (widget.iconColor ?? widget.accent).withOpacity(0.8),
            size: effectiveCompact ? 20 : 24,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: effectiveCompact ? 14 : 15,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(effectiveCompact ? 12 : 14),
          elevation: 8,
          menuMaxHeight: 300,
          itemHeight: effectiveCompact ? 48 : 52,
          selectedItemBuilder: (BuildContext context) {
            return widget.dropdownItems?.map<Widget>((String item) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: effectiveCompact ? 14 : 15,
                        color: (widget.iconColor ?? widget.accent),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList() ??
                [];
          },
          items: widget.dropdownItems?.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: effectiveCompact ? 8 : 12,
                ),
                child: Text(
                  item,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: effectiveCompact ? 14 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: widget.onDropdownChanged,
        ),
      ),
    );
  }

  Widget _buildEnhancedSlider(BuildContext context, bool effectiveCompact) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: effectiveCompact ? 4 : 8,
        vertical: effectiveCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveCompact ? 12 : 14),
        color: theme.brightness == Brightness.dark
            ? Colors.grey[850]?.withOpacity(0.3)
            : Colors.grey[50]?.withOpacity(0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: widget.accent,
                inactiveTrackColor: widget.accent.withOpacity(0.2),
                thumbColor: widget.accent,
                overlayColor: widget.accent.withOpacity(0.15),
                trackHeight: effectiveCompact ? 3 : 4,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: effectiveCompact ? 8 : 10,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: effectiveCompact ? 16 : 20,
                ),
                tickMarkShape: const RoundSliderTickMarkShape(
                  tickMarkRadius: 2,
                ),
                activeTickMarkColor: widget.accent.withOpacity(0.7),
                inactiveTickMarkColor: widget.accent.withOpacity(0.3),
              ),
              child: Slider(
                value: widget.sliderValue ?? 0,
                min: widget.sliderMin ?? 0,
                max: widget.sliderMax ?? 100,
                divisions: widget.sliderDivisions,
                onChanged: widget.onSliderChanged,
              ),
            ),
          ),
          SizedBox(width: effectiveCompact ? 8 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: effectiveCompact ? 8 : 10,
              vertical: effectiveCompact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: widget.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(effectiveCompact ? 8 : 10),
            ),
            child: Text(
              '${(widget.sliderValue ?? 0).toStringAsFixed(widget.sliderDivisions != null ? 0 : 1)}${widget.sliderSuffix ?? ''}',
              style: TextStyle(
                fontSize: effectiveCompact ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: widget.accent,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDefaultTrailing() {
    return widget.trailingWidgets == null &&
        widget.type != SettingsItemType.slider &&
        widget.type != SettingsItemType.dropdown &&
        widget.type != SettingsItemType.segmentedToggle;
  }

  Widget _buildDefaultTrailingWidget(bool effectiveCompact) {
    final theme = Theme.of(context);

    switch (widget.type) {
      case SettingsItemType.selectable:
        if (widget.isSelected) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: effectiveCompact ? 24 : 28,
            height: effectiveCompact ? 24 : 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.iconColor ?? widget.accent,
                  (widget.iconColor ?? widget.accent).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(effectiveCompact ? 12 : 14),
              boxShadow: [
                BoxShadow(
                  color: (widget.iconColor ?? widget.accent).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: effectiveCompact ? 16 : 18,
              color: Colors.white,
            ),
          );
        } else {
          return const SizedBox.shrink();
        }

      case SettingsItemType.toggleable:
        return Transform.scale(
          scale: effectiveCompact ? 0.85 : 1.0,
          child: Switch.adaptive(
            value: widget.toggleValue ?? false,
            onChanged: widget.onToggleChanged,
            activeColor: widget.iconColor ?? widget.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

      case SettingsItemType.normal:
      default:
        return Icon(
          Iconsax.arrow_right_3,
          size: effectiveCompact ? 18 : 20,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
        );
    }
  }

  ResponsiveDimensions _getResponsiveDimensions(
      bool effectiveCompact, bool isSmallScreen) {
    return ResponsiveDimensions(
      iconSize: effectiveCompact ? 22 : (isSmallScreen ? 24 : 26),
      iconContainerSize: effectiveCompact ? 44 : (isSmallScreen ? 48 : 52),
      titleFontSize: effectiveCompact ? 15 : (isSmallScreen ? 16 : 17),
      descriptionFontSize: effectiveCompact ? 12 : (isSmallScreen ? 12.5 : 13),
      padding: effectiveCompact
          ? const EdgeInsets.all(16.0)
          : (isSmallScreen
              ? const EdgeInsets.all(18.0)
              : const EdgeInsets.all(20.0)),
      spacing: effectiveCompact ? 14 : (isSmallScreen ? 16 : 18),
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