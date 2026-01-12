import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    required super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.roundness,
    super.isCompact,
    super.layoutType,
    super.focusNode,
    super.autofocus,
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
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): () => _nudgeValue(-1),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): () => _nudgeValue(1),
      },
      child: buildWithTap(
        context,
        () {},
      ),
    );
  }

  void _nudgeValue(int direction) {
    if (direction == 0) return;
    final step = divisions != null && divisions! > 0
        ? (max - min) / divisions!
        : (max - min) / 20;
    final next = (value + (step * direction)).clamp(min, max);
    if ((next - value).abs() < 0.000001) return;
    onChanged(next);
  }

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
            child: ExcludeFocus(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
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
