import 'package:flutter/material.dart';

enum SettingsItemLayout { auto, horizontal, vertical }

const double kM3ExpressiveRadiusLarge = 28.0;
const double kM3ExpressiveRadiusMedium = 20.0;
const double kM3ExpressiveRadiusSmall = 12.0;

abstract class BaseSettingsItem extends StatelessWidget {
  final Widget? leading;
  final Icon? icon;
  final Color? iconColor;
  final Color? accent;
  final String title;
  final String description;
  final VoidCallback? onTap;
  
  // M3 Expressive Params
  final bool isExpressive; 
  final double? roundness;
  final Color? containerColor;
  
  final bool isCompact;
  final List<Widget>? trailingWidgets;
  final SettingsItemLayout layoutType;

  const BaseSettingsItem({
    super.key,
    this.icon,
    this.iconColor,
    this.accent,
    required this.title,
    this.description = '',
    this.leading,
    this.onTap,
    this.isExpressive = true,
    this.roundness,
    this.containerColor,
    this.isCompact = false,
    this.trailingWidgets,
    this.layoutType = SettingsItemLayout.auto,
  });

  /// Helper for Squircle shape
  ShapeBorder _getShape(double radius) {
    if (isExpressive) {
      return ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(radius * 2.5),
      );
    }
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 600;
    
    final double effectiveRadius = roundness ?? 
        (isExpressive ? kM3ExpressiveRadiusMedium : kM3ExpressiveRadiusSmall);

    final effectiveCompact = isCompact || isSmallScreen;

    final dimensions = _getResponsiveDimensions(
      context,
      effectiveCompact,
      isSmallScreen,
    );

    final effectiveContainerColor = containerColor ?? 
        (isExpressive 
            ? colorScheme.surfaceContainerLow 
            : colorScheme.surface);

    return Material(
      color: effectiveContainerColor,
      elevation: 0,
      shape: _getShape(effectiveRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: _getShape(effectiveRadius),
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
    );
  }

  Widget _buildLayout(
    BuildContext context,
    bool effectiveCompact,
    bool isSmallScreen,
    ResponsiveDimensions dimensions,
  ) {
    final bool useVerticalLayout = _shouldUseVerticalLayout(isSmallScreen);

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
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final effectiveAccent = accent ?? colorScheme.primary;
    final effectiveIconColor = iconColor ?? effectiveAccent;

    return Container(
      width: dimensions.iconContainerSize,
      height: dimensions.iconContainerSize,
      decoration: BoxDecoration(
        color: isExpressive 
            ? effectiveAccent.withOpacity(0.12)
            : Colors.transparent, 
        borderRadius: isExpressive
             ? BorderRadius.circular(12)
             : BorderRadius.circular(effectiveCompact ? 8 : 10),
        shape: isExpressive ? BoxShape.rectangle : BoxShape.rectangle, 
      ),
      child: Center(
        child: (icon != null)
            ? IconTheme(
                data: IconThemeData(
                  color: effectiveIconColor,
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
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions, {
    bool isVertical = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      flex: isVertical ? 0 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isExpressive ? FontWeight.w600 : FontWeight.w500,
              color: colorScheme.onSurface,
              fontSize: dimensions.titleFontSize,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: (effectiveCompact || isVertical) ? 1 : 2,
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 2),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: dimensions.descriptionFontSize,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: (effectiveCompact || isVertical) ? 2 : 3,
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
    BuildContext context,
    bool effectiveCompact,
    bool isSmallScreen,
  ) {
    return ResponsiveDimensions(
      iconSize: effectiveCompact ? 22 : 24,
      iconContainerSize: effectiveCompact ? 44 : 52,
      titleFontSize: effectiveCompact ? 14 : 16,
      descriptionFontSize: effectiveCompact ? 12 : 13,
      padding: effectiveCompact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      spacing: effectiveCompact ? 12 : 16,
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