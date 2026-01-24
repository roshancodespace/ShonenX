import 'package:flutter/material.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';

class ColorPickerSettingsItem extends BaseSettingsItem {
  final int selectedColor;
  final ValueChanged<int> onColorChanged;
  final List<int> colors;

  const ColorPickerSettingsItem({
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
    super.layoutType,
    required this.selectedColor,
    required this.onColorChanged,
    this.colors = const [
      0xFFFFFFFF, // White
      0xFFFFFF00, // Yellow
      0xFF00FFFF, // Cyan
      0xFF00FF00, // Green
      0xFFFF00FF, // Magenta
      0xFFFF0000, // Red
      0xFF0000FF, // Blue
      0xFF000000, // Black
    ],
  }) : super(onTap: null);

  @override
  bool needsVerticalLayoutByContent() => true;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null || leading != null) ...[
              buildIconContainer(context, effectiveCompact, dimensions),
              SizedBox(width: dimensions.spacing),
            ],
            buildTitleAndDescription(context, effectiveCompact, dimensions),
          ],
        ),
        SizedBox(height: effectiveCompact ? 12 : 16),
        _buildColorList(context, effectiveCompact),
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

  Widget _buildColorList(BuildContext context, bool effectiveCompact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeRingColor = accent ?? colorScheme.primary;
    final swatchSize = effectiveCompact ? 40.0 : 48.0;

    return SizedBox(
      height: swatchSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: colors.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: effectiveCompact ? 10 : 14),
        itemBuilder: (context, index) {
          final colorValue = colors[index];
          final isSelected = selectedColor == colorValue;
          final color = Color(colorValue);
          
          final isLightColor = color.computeLuminance() > 0.5;

          return GestureDetector(
            onTap: () => onColorChanged(colorValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: swatchSize,
              height: swatchSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: isSelected
                    ? Border.all(
                        color: activeRingColor,
                        width: 2.5,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeRingColor.withOpacity(0.25),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: isLightColor ? Colors.black87 : Colors.white,
                      size: effectiveCompact ? 20 : 22,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
