import 'package:material_ui/material_ui.dart';

class M3ESlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final double trackHeight;
  final double trackGap;
  final double thumbWidth;
  final double pressedThumbWidth;
  final double thumbHeight;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;
  final Color? disabledActiveTrackColor;
  final Color? disabledInactiveTrackColor;
  final Color? disabledThumbColor;
  final Color? valueIndicatorColor;
  final TextStyle? valueIndicatorTextStyle;
  final bool showStopIndicator;
  final EdgeInsetsGeometry? padding;

  const M3ESlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.trackHeight = 8.0,
    this.trackGap = 4.0,
    this.thumbWidth = 4.0,
    this.pressedThumbWidth = 2.0,
    this.thumbHeight = 24.0,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.disabledActiveTrackColor,
    this.disabledInactiveTrackColor,
    this.disabledThumbColor,
    this.valueIndicatorColor,
    this.valueIndicatorTextStyle,
    this.showStopIndicator = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: trackHeight,
        trackGap: trackGap,
        thumbShape: const HandleThumbShape(),
        trackShape: const GappedSliderTrackShape(),
        thumbSize: WidgetStateProperty.resolveWith((states) {
          final w = states.contains(WidgetState.pressed)
              ? pressedThumbWidth
              : thumbWidth;
          return Size(w, thumbHeight);
        }),
        activeTrackColor: activeTrackColor ?? cs.primary,
        inactiveTrackColor:
            inactiveTrackColor ?? cs.secondaryContainer.withValues(alpha: 0.7),
        thumbColor: thumbColor ?? cs.primary,
        disabledActiveTrackColor:
            disabledActiveTrackColor ?? cs.onSurface.withValues(alpha: 0.38),
        disabledInactiveTrackColor:
            disabledInactiveTrackColor ?? cs.onSurface.withValues(alpha: 0.12),
        disabledThumbColor:
            disabledThumbColor ?? cs.onSurface.withValues(alpha: 0.38),
        valueIndicatorColor: valueIndicatorColor ?? cs.inverseSurface,
        valueIndicatorTextStyle:
            valueIndicatorTextStyle ??
            theme.textTheme.labelMedium?.copyWith(color: cs.onInverseSurface),
        activeTickMarkColor: showStopIndicator ? null : Colors.transparent,
        inactiveTickMarkColor: showStopIndicator ? null : Colors.transparent,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor: mouseCursor,
        padding: padding,
        year2023: false,
      ),
    );
  }
}
