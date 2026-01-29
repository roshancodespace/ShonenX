import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
      0xFFFFFFFF,
      0xFFFFFF00,
      0xFF00FFFF,
      0xFF00FF00,
      0xFFFF00FF,
      0xFFFF0000,
      0xFF0000FF,
      0xFF000000,
    ],
  }) : super(onTap: null);

  @override
  bool needsVerticalLayoutByContent() => false;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _openColorPickerDialog(context),
      child: Row(
        children: [
          if (icon != null || leading != null) ...[
            buildIconContainer(context, effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
          ],
          Expanded(
            child: buildTitleAndDescription(
              context,
              effectiveCompact,
              dimensions,
            ),
          ),

          // Current color preview with a "glow" because we're fancy
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color(selectedColor),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color(selectedColor).withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildVerticalLayout(context, effectiveCompact, dimensions) =>
      buildHorizontalLayout(context, effectiveCompact, dimensions);

  void _openColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int tempColor = selectedColor;
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text('Customize Color'),
          content: Column(
            children: [
              ColorPicker(
                pickerColor: Color(selectedColor),
                onColorChanged: (color) => tempColor = color.value,
                colorPickerWidth: 300,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: true,
                displayThumbColor: true,
                paletteType: PaletteType.hsvWithHue,
                labelTypes: const [],
                pickerAreaBorderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Presets',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: colors
                    .map(
                      (c) => GestureDetector(
                        onTap: () {
                          onColorChanged(c);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
