import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/features/player/providers/media_kit_prefs_provider.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_sheet_action.dart';

class VideoAdjustmentsOverlay {
  const VideoAdjustmentsOverlay._();

  static void show(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Color Adjustments',
      titleIcon: Icons.tune_rounded,
      isFloating: true,
      barrierColor: Colors.transparent,
      maxWidth: 500,
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: const [_ResetAction()],
      child: const VideoAdjustments(),
    );
  }
}

class _ResetAction extends ConsumerWidget {
  const _ResetAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(mediaKitPrefsProvider);
    final notifier = ref.read(mediaKitPrefsProvider.notifier);

    final isDefault =
        prefs.brightness == 0 &&
        prefs.contrast == 0 &&
        prefs.saturation == 0 &&
        prefs.gamma == 0 &&
        prefs.hue == 0;

    if (isDefault) return const SizedBox.shrink();

    return AppSheetAction(
      tooltip: 'Reset to default',
      icon: Icons.refresh_rounded,
      onTap: () => notifier.updatePrefs(
        prefs.copyWith(
          brightness: 0,
          contrast: 0,
          saturation: 0,
          gamma: 0,
          hue: 0,
          colorPreset: MediaKitColorPreset.default_,
        ),
      ),
    );
  }
}

extension on MediaKitColorPreset {
  IconData get icon => switch (this) {
    MediaKitColorPreset.default_ => Icons.replay_rounded,
    MediaKitColorPreset.vibrant => Icons.auto_awesome_rounded,
    MediaKitColorPreset.anime => Icons.animation_rounded,
    MediaKitColorPreset.film => Icons.movie_filter_rounded,
    MediaKitColorPreset.cool => Icons.ac_unit_rounded,
    MediaKitColorPreset.warm => Icons.wb_sunny_rounded,
  };

  String get shortLabel => switch (this) {
    MediaKitColorPreset.default_ => 'Default',
    MediaKitColorPreset.vibrant => 'Vibrant',
    MediaKitColorPreset.anime => 'Anime',
    MediaKitColorPreset.film => 'Film',
    MediaKitColorPreset.cool => 'Cool',
    MediaKitColorPreset.warm => 'Warm',
  };
}

class VideoAdjustments extends ConsumerWidget {
  const VideoAdjustments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(mediaKitPrefsProvider);
    final notifier = ref.read(mediaKitPrefsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final roundness = GlobalUI.uiRoundness;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Presets Bar
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: MediaKitColorPreset.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final preset = MediaKitColorPreset.values[i];
                final isActive =
                    prefs.colorPreset == preset &&
                    prefs.brightness == preset.brightness &&
                    prefs.contrast == preset.contrast &&
                    prefs.saturation == preset.saturation &&
                    prefs.gamma == preset.gamma &&
                    prefs.hue == preset.hue;

                return _PresetPill(
                  preset: preset,
                  isSelected: isActive,
                  onTap: () => notifier.updatePrefs(
                    prefs.copyWith(
                      colorPreset: preset,
                      brightness: preset.brightness,
                      contrast: preset.contrast,
                      saturation: preset.saturation,
                      gamma: preset.gamma,
                      hue: preset.hue,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // 2. Adjustments Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(roundness),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AdjustmentRow(
                  label: 'Brightness',
                  icon: Icons.brightness_6_rounded,
                  value: prefs.brightness,
                  onChanged: (v) =>
                      notifier.updatePrefs(prefs.copyWith(brightness: v)),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                ),
                _AdjustmentRow(
                  label: 'Contrast',
                  icon: Icons.contrast_rounded,
                  value: prefs.contrast,
                  onChanged: (v) =>
                      notifier.updatePrefs(prefs.copyWith(contrast: v)),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                ),
                _AdjustmentRow(
                  label: 'Saturation',
                  icon: Icons.palette_rounded,
                  value: prefs.saturation,
                  onChanged: (v) =>
                      notifier.updatePrefs(prefs.copyWith(saturation: v)),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                ),
                _AdjustmentRow(
                  label: 'Gamma',
                  icon: Icons.tonality_rounded,
                  value: prefs.gamma,
                  onChanged: (v) =>
                      notifier.updatePrefs(prefs.copyWith(gamma: v)),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                ),
                _AdjustmentRow(
                  label: 'Hue',
                  icon: Icons.color_lens_outlined,
                  value: prefs.hue,
                  onChanged: (v) =>
                      notifier.updatePrefs(prefs.copyWith(hue: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  final MediaKitColorPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetPill({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final roundness = GlobalUI.uiRoundness;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(roundness),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary
                : cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(roundness),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.35),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                preset.icon,
                size: 15,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                preset.shortLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  const _AdjustmentRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final roundness = GlobalUI.uiRoundness;
    final isModified = value != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: isModified ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: isModified ? FontWeight.w600 : FontWeight.w500,
                color: isModified ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackShape: const CenterZeroSliderTrackShape(),
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7,
                  elevation: 1.5,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.surfaceContainerHighest.withValues(
                  alpha: 0.8,
                ),
                thumbColor: cs.primary,
                overlayColor: cs.primary.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value.toDouble(),
                min: -100,
                max: 100,
                divisions: 200,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Tap to reset',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isModified ? () => onChanged(0) : null,
                borderRadius: BorderRadius.circular(roundness),
                child: Container(
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isModified
                        ? cs.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(roundness),
                    border: isModified
                        ? Border.all(
                            color: cs.primary.withValues(alpha: 0.3),
                            width: 0.8,
                          )
                        : null,
                  ),
                  child: Text(
                    value > 0 ? '+$value' : '$value',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isModified
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isModified
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CenterZeroSliderTrackShape extends RoundedRectSliderTrackShape {
  const CenterZeroSliderTrackShape();

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
    double additionalActiveTrackHeight = 1,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final trackRadius = Radius.circular(trackRect.height / 2);
    final centerDx = (trackRect.left + trackRect.right) / 2;

    // Paint full inactive track
    final inactivePaint = Paint()
      ..color =
          sliderTheme.inactiveTrackColor ?? Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      inactivePaint,
    );

    // Paint active track outward from center (0) to thumb
    final activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    if ((thumbCenter.dx - centerDx).abs() > 1.5) {
      final activeLeft = thumbCenter.dx < centerDx ? thumbCenter.dx : centerDx;
      final activeRight = thumbCenter.dx > centerDx ? thumbCenter.dx : centerDx;
      final activeRect = Rect.fromLTRB(
        activeLeft,
        trackRect.top - (additionalActiveTrackHeight / 2),
        activeRight,
        trackRect.bottom + (additionalActiveTrackHeight / 2),
      );
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          activeRect,
          Radius.circular(activeRect.height / 2),
        ),
        activePaint,
      );
    }

    // Paint subtle center tick notch at zero
    final tickColor = (sliderTheme.activeTrackColor ?? Colors.blue).withValues(
      alpha: 0.6,
    );
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    context.canvas.drawLine(
      Offset(centerDx, trackRect.top - 2.5),
      Offset(centerDx, trackRect.bottom + 2.5),
      tickPaint,
    );
  }
}
