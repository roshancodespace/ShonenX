import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

enum AppSliderStyle { adaptive, expressive, classic }

class AppSliderMarker {
  final double start;
  final double end;
  final Color color;

  const AppSliderMarker({
    required this.start,
    required this.end,
    required this.color,
  });
}

class AppSlider extends ConsumerWidget {
  final double value;
  final double? secondaryTrackValue;
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
  final AppSliderStyle style;
  final double trackHeight;
  final double trackGap;
  final double thumbWidth;
  final double pressedThumbWidth;
  final double thumbHeight;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? secondaryActiveTrackColor;
  final Color? thumbColor;
  final Color? disabledActiveTrackColor;
  final Color? disabledInactiveTrackColor;
  final Color? disabledThumbColor;
  final Color? valueIndicatorColor;
  final TextStyle? valueIndicatorTextStyle;
  final bool showStopIndicator;
  final EdgeInsetsGeometry? padding;
  final List<AppSliderMarker> markers;

  const AppSlider({
    super.key,
    required this.value,
    this.secondaryTrackValue,
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
    this.style = AppSliderStyle.adaptive,
    this.trackHeight = 14.0,
    this.trackGap = 6.0,
    this.thumbWidth = 4.0,
    this.pressedThumbWidth = 2.0,
    this.thumbHeight = 36.0,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.secondaryActiveTrackColor,
    this.thumbColor,
    this.disabledActiveTrackColor,
    this.disabledInactiveTrackColor,
    this.disabledThumbColor,
    this.valueIndicatorColor,
    this.valueIndicatorTextStyle,
    this.showStopIndicator = true,
    this.padding,
    this.markers = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uiStyle = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final useExpressive = switch (style) {
      AppSliderStyle.adaptive => uiStyle == SettingsStyle.expressive,
      AppSliderStyle.expressive => true,
      AppSliderStyle.classic => false,
    };

    final safeMax = max > min ? max : min + 1.0;
    final clampedValue = value.clamp(min, safeMax);
    final clampedSecondary = secondaryTrackValue?.clamp(min, safeMax);

    final SliderThemeData sliderTheme;
    if (useExpressive) {
      sliderTheme = SliderTheme.of(context).copyWith(
        trackHeight: trackHeight,
        trackGap: trackGap,
        padding: padding ?? EdgeInsets.zero,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 6.0),
        thumbShape: const HandleThumbShape(),
        trackShape: markers.isEmpty
            ? const GappedSliderTrackShape()
            : _MarkedGappedTrackShape(markers: markers),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2.0),
        thumbSize: WidgetStateProperty.resolveWith((states) {
          final pressed =
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused);
          return Size(pressed ? pressedThumbWidth : thumbWidth, thumbHeight);
        }),
        activeTrackColor: activeTrackColor ?? cs.primary,
        inactiveTrackColor: inactiveTrackColor ?? cs.secondaryContainer,
        secondaryActiveTrackColor:
            secondaryActiveTrackColor ?? cs.primary.withValues(alpha: 0.35),
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
        activeTickMarkColor: showStopIndicator
            ? cs.onPrimary.withValues(alpha: 0.7)
            : Colors.transparent,
        inactiveTickMarkColor: showStopIndicator
            ? cs.onSecondaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
      );
    } else {
      sliderTheme = SliderTheme.of(context).copyWith(
        trackHeight: 4.0,
        padding: padding,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
        trackShape: markers.isEmpty
            ? const RoundedRectSliderTrackShape()
            : _MarkedClassicTrackShape(markers: markers),
        activeTrackColor: activeTrackColor ?? cs.primary,
        inactiveTrackColor:
            inactiveTrackColor ??
            cs.surfaceContainerHighest.withValues(alpha: 0.8),
        secondaryActiveTrackColor:
            secondaryActiveTrackColor ?? cs.primary.withValues(alpha: 0.35),
        thumbColor: thumbColor ?? cs.primary,
        activeTickMarkColor: showStopIndicator ? null : Colors.transparent,
        inactiveTickMarkColor: showStopIndicator ? null : Colors.transparent,
      );
    }

    return SliderTheme(
      data: sliderTheme,
      child: Slider(
        value: clampedValue,
        secondaryTrackValue: clampedSecondary,
        min: min,
        max: safeMax,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor: mouseCursor,
        padding: padding ?? (useExpressive ? EdgeInsets.zero : null),
      ),
    );
  }
}

void _paintTrackMarkers(
  Canvas canvas,
  Rect trackRect,
  List<AppSliderMarker> markers, {
  double? thumbCenterX,
  double thumbGap = 0.0,
}) {
  if (markers.isEmpty || trackRect.width <= 0) return;
  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndRadius(trackRect, Radius.circular(trackRect.height / 2)),
  );
  for (final marker in markers) {
    final s = marker.start.clamp(0.0, 1.0);
    final e = marker.end.clamp(0.0, 1.0);
    if (e <= s) continue;
    final left = trackRect.left + s * trackRect.width;
    final right = trackRect.left + e * trackRect.width;
    final paint = Paint()..color = marker.color;

    if (thumbCenterX != null && thumbGap > 0) {
      final gapLeft = thumbCenterX - thumbGap;
      final gapRight = thumbCenterX + thumbGap;
      if (left < gapLeft) {
        final segRight = right < gapLeft ? right : gapLeft;
        if (segRight > left) {
          canvas.drawRect(
            Rect.fromLTRB(left, trackRect.top, segRight, trackRect.bottom),
            paint,
          );
        }
      }
      if (right > gapRight) {
        final segLeft = left > gapRight ? left : gapRight;
        if (right > segLeft) {
          canvas.drawRect(
            Rect.fromLTRB(segLeft, trackRect.top, right, trackRect.bottom),
            paint,
          );
        }
      }
    } else {
      canvas.drawRect(
        Rect.fromLTRB(left, trackRect.top, right, trackRect.bottom),
        paint,
      );
    }
  }
  canvas.restore();
}

class _MarkedGappedTrackShape extends GappedSliderTrackShape {
  final List<AppSliderMarker> markers;

  const _MarkedGappedTrackShape({required this.markers});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    _paintTrackMarkers(
      context.canvas,
      trackRect,
      markers,
      thumbCenterX: thumbCenter.dx,
      thumbGap: sliderTheme.trackGap ?? 0.0,
    );
  }
}

class _MarkedClassicTrackShape extends RoundedRectSliderTrackShape {
  final List<AppSliderMarker> markers;

  const _MarkedClassicTrackShape({required this.markers});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    _paintTrackMarkers(context.canvas, trackRect, markers);
  }
}
