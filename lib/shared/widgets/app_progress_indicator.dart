import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

enum AppProgressType { circular, linear }

enum AppProgressStyle { adaptive, wavy, classic }

class AppProgressIndicator extends ConsumerWidget {
  final AppProgressType type;
  final AppProgressStyle style;
  final double? value;
  final Color? color;
  final Color? trackColor;
  final double? strokeWidth;
  final double? size;
  final double height;
  final BorderRadius? borderRadius;
  final bool animate;
  final bool showTrack;
  final String? semanticsLabel;
  final String? semanticsValue;

  const AppProgressIndicator({
    super.key,
    required this.type,
    this.style = AppProgressStyle.adaptive,
    this.value,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.size,
    this.height = 4.0,
    this.borderRadius,
    this.animate = true,
    this.showTrack = true,
    this.semanticsLabel,
    this.semanticsValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final uiStyle = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final useWavy = switch (style) {
      AppProgressStyle.adaptive => uiStyle == SettingsStyle.expressive,
      AppProgressStyle.wavy => true,
      AppProgressStyle.classic => false,
    };

    final activeColor = color ?? cs.primary;
    final bgColor =
        trackColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.65);
    final target = value?.clamp(0.0, 1.0);

    Widget buildIndicator(double? v) {
      if (type == AppProgressType.linear) {
        if (useWavy) {
          return M3EProgressIndicator.linearWavy(
            value: v,
            linearSize: M3EProgressIndicatorSize.s,
            color: activeColor,
            trackColor: bgColor,
            strokeWidth: height,
            trackStrokeWidth: height,
            showTrack: showTrack,
            semanticsLabel: semanticsLabel,
            semanticsValue: semanticsValue,
          );
        }
        return LinearProgressIndicator(
          value: v,
          minHeight: height,
          borderRadius: borderRadius ?? BorderRadius.circular(999),
          backgroundColor: bgColor,
          color: activeColor,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        );
      }

      if (useWavy) {
        final isCompact = size != null && size! < 28;
        if (isCompact) {
          return M3EProgressIndicator.circular(
            value: v,
            size: size,
            strokeWidth: strokeWidth ?? 2.2,
            trackStrokeWidth: strokeWidth ?? 2.2,
            color: activeColor,
            trackColor: bgColor,
            showTrack: showTrack,
            semanticsLabel: semanticsLabel,
            semanticsValue: semanticsValue,
          );
        }
        return M3EProgressIndicator.circularWavy(
          value: v,
          size: size,
          strokeWidth: strokeWidth,
          trackStrokeWidth: strokeWidth,
          color: activeColor,
          trackColor: bgColor,
          showTrack: showTrack,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        );
      }

      final indicator = CircularProgressIndicator(
        value: v,
        strokeWidth: strokeWidth ?? 4.0,
        color: activeColor,
        backgroundColor: trackColor,
        semanticsLabel: semanticsLabel,
        semanticsValue: semanticsValue,
      );
      return size != null
          ? SizedBox.square(dimension: size, child: indicator)
          : indicator;
    }

    if (target == null || !animate) {
      return buildIndicator(target);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => buildIndicator(animatedValue),
    );
  }
}
