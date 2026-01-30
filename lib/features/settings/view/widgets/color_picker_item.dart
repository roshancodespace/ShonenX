import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
          content: ColorPicker(
            color: Color(selectedColor),
            onColorChanged: (color) => tempColor = color.value,
            width: 40,
            height: 40,
            borderRadius: 4,
            spacing: 5,
            runSpacing: 5,
            wheelDiameter: 200,
            heading: Text(
              'Select color',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subheading: Text(
              'Select color shade',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            wheelSubheading: Text(
              'Selected color and its shades',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            showMaterialName: true,
            showColorName: true,
            showColorCode: true,
            copyPasteBehavior: const ColorPickerCopyPasteBehavior(
              longPressMenu: true,
            ),
            materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
            colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
            colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.bw: false,
              ColorPickerType.custom: false,
              ColorPickerType.wheel: true,
            },
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
