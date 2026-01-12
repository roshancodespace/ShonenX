import 'package:flutter/material.dart';
import 'package:shonenx/shared/widgets/focusable_tap.dart';

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
  final FocusNode? focusNode;
  final bool autofocus;

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
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return buildWithTap(context, onTap);
  }

  @protected
  Widget buildWithTap(
    BuildContext context,
    VoidCallback? onTapOverride,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final effectiveCompact = isCompact || isSmallScreen;

    final dimensions =
        _getResponsiveDimensions(effectiveCompact, isSmallScreen);

    final borderRadius = BorderRadius.circular(roundness);
    final content = Padding(
      padding: dimensions.padding,
      child: _buildLayout(
        context,
        effectiveCompact,
        isSmallScreen,
        dimensions,
      ),
    );

    final Widget child = onTapOverride != null
        ? FocusableTap(
            onTap: onTapOverride,
            borderRadius: borderRadius,
            focusNode: focusNode,
            autofocus: autofocus,
            child: content,
          )
        : content;

    return Card(
      elevation: effectiveCompact ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
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
