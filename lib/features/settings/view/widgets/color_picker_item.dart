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
    required super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.roundness,
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
            buildIconContainer(effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
            buildTitleAndDescription(effectiveCompact, dimensions),
          ],
        ),
        SizedBox(height: effectiveCompact ? 8 : 12),
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
    return SizedBox(
      height: effectiveCompact ? 40 : 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: effectiveCompact ? 8 : 12),
        itemBuilder: (context, index) {
          final colorValue = colors[index];
          final isSelected = selectedColor == colorValue;
          final color = Color(colorValue);

          return GestureDetector(
            onTap: () => onColorChanged(colorValue),
            child: Container(
              width: effectiveCompact ? 40 : 50,
              height: effectiveCompact ? 40 : 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accent : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      size: effectiveCompact ? 20 : 24,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
