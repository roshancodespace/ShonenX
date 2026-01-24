import 'package:flutter/material.dart';
import 'base_settings_item.dart';

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
    super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.isExpressive,
    super.roundness,
    super.containerColor,
    super.isCompact,
    super.layoutType,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.suffix,
  }) : super(onTap: null); 

  @override
  bool needsVerticalLayoutByContent() => true;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null || leading != null) ...[
            buildIconContainer(context, effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
          ],
          buildTitleAndDescription(context, effectiveCompact, dimensions),
          SizedBox(width: dimensions.spacing),
          Expanded(
            flex: 2,
            child: Center(
              child: _buildSlider(context, effectiveCompact),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             if (icon != null || leading != null) ...[
              buildIconContainer(context, effectiveCompact, dimensions),
              SizedBox(width: dimensions.spacing),
            ],
            buildTitleAndDescription(
              context,
              effectiveCompact,
              dimensions,
              isVertical: true,
            ),
          ],
        ),
        SizedBox(height: effectiveCompact ? 8 : 12),
        _buildSlider(context, effectiveCompact),
      ],
    );
  }

  Widget _buildSlider(BuildContext context, bool effectiveCompact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = accent ?? colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: effectiveColor,
              inactiveTrackColor: effectiveColor.withOpacity(0.12),
              thumbColor: effectiveColor,
              overlayColor: effectiveColor.withOpacity(0.12),
              trackHeight: effectiveCompact ? 2 : 4,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: effectiveCompact ? 6 : 8,
                elevation: 0, 
                pressedElevation: 2,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: effectiveCompact ? 14 : 20,
              ),
              trackShape: const RoundedRectSliderTrackShape(),
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
        SizedBox(width: effectiveCompact ? 8 : 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8, 
            vertical: effectiveCompact ? 2 : 4
          ),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '${(value).toStringAsFixed(divisions != null ? 0 : 1)}${suffix ?? ''}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: effectiveColor,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}