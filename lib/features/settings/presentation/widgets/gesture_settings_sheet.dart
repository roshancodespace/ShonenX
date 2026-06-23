import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/gesture_prefs.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class GestureSettingsSheet extends ConsumerWidget {
  const GestureSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playerPrefsProvider.select((p) => p.gesturePrefs));
    final notifier = ref.read(playerPrefsProvider.notifier);

    return AppBottomSheet(
      title: 'Gesture Areas',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
        child: _LivePreview(
          prefs: prefs,
          onChanged: notifier.updateGesturePrefs,
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final GesturePrefs prefs;
  final ValueChanged<GesturePrefs> onChanged;

  const _LivePreview({required this.prefs, required this.onChanged});

  String _pct(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final left = prefs.leftMargin * w;
          final right = prefs.rightMargin * w;
          final top = prefs.topMargin * h;
          final bottom = prefs.bottomMargin * h;

          final safeW = math.max(1.0, w - left - right);
          final safeH = math.max(1.0, h - top - bottom);

          return Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: top,
                  bottom: bottom,
                  left: left,
                  right: right,
                  child: ColoredBox(color: cs.surface),
                ),
                Positioned(
                  top: 0,
                  left: left,
                  right: right,
                  height: top,
                  child: _deadZone(cs, _pct(prefs.topMargin)),
                ),
                Positioned(
                  bottom: 0,
                  left: left,
                  right: right,
                  height: bottom,
                  child: _deadZone(cs, _pct(prefs.bottomMargin)),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: left,
                  child: _deadZone(cs, _pct(prefs.leftMargin)),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: right,
                  child: _deadZone(cs, _pct(prefs.rightMargin)),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: safeW,
                  height: safeH,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: prefs.leftWidth,
                          heightFactor: 1,
                          child: _gestureArea(
                            bgColor: cs.primaryContainer.withValues(alpha: 0.5),
                            fgColor: cs.onPrimaryContainer,
                            icon: Icons.light_mode_rounded,
                            percent: _pct(prefs.leftWidth),
                            isLeft: true,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: prefs.rightWidth,
                          heightFactor: 1,
                          child: _gestureArea(
                            bgColor: cs.tertiaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            fgColor: cs.onTertiaryContainer,
                            icon: Icons.volume_up_rounded,
                            percent: _pct(prefs.rightWidth),
                            isLeft: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: left + (prefs.leftWidth * safeW) - 24,
                  top: top,
                  bottom: bottom,
                  width: 48,
                  child: _dragHandle(
                    axis: Axis.horizontal,
                    color: cs.primary,
                    onDrag: (d) {
                      final currentWidthPx = prefs.leftWidth * safeW;
                      final newWidthPx = currentWidthPx + d.delta.dx;
                      final v = (newWidthPx / safeW).clamp(0.1, 0.45);
                      onChanged(prefs.copyWith(leftWidth: v));
                    },
                  ),
                ),
                Positioned(
                  right: right + (prefs.rightWidth * safeW) - 24,
                  top: top,
                  bottom: bottom,
                  width: 48,
                  child: _dragHandle(
                    axis: Axis.horizontal,
                    color: cs.tertiary,
                    onDrag: (d) {
                      final currentWidthPx = prefs.rightWidth * safeW;
                      final newWidthPx = currentWidthPx - d.delta.dx;
                      final v = (newWidthPx / safeW).clamp(0.1, 0.45);
                      onChanged(prefs.copyWith(rightWidth: v));
                    },
                  ),
                ),
                Positioned(
                  top: math.max(0, top - 24),
                  left: 0,
                  right: 0,
                  height: 48,
                  child: _dragHandle(
                    axis: Axis.vertical,
                    color: cs.outline,
                    onDrag: (d) {
                      final v = ((top + d.delta.dy) / h).clamp(0.0, 0.35);
                      onChanged(prefs.copyWith(topMargin: v));
                    },
                  ),
                ),
                Positioned(
                  bottom: math.max(0, bottom - 24),
                  left: 0,
                  right: 0,
                  height: 48,
                  child: _dragHandle(
                    axis: Axis.vertical,
                    color: cs.outline,
                    onDrag: (d) {
                      final v = ((bottom - d.delta.dy) / h).clamp(0.0, 0.35);
                      onChanged(prefs.copyWith(bottomMargin: v));
                    },
                  ),
                ),
                Positioned(
                  left: math.max(0, left - 24),
                  top: 0,
                  bottom: 0,
                  width: 48,
                  child: _dragHandle(
                    axis: Axis.horizontal,
                    color: cs.outline,
                    onDrag: (d) {
                      final v = ((left + d.delta.dx) / w).clamp(0.0, 0.35);
                      onChanged(prefs.copyWith(leftMargin: v));
                    },
                  ),
                ),
                Positioned(
                  right: math.max(0, right - 24),
                  top: 0,
                  bottom: 0,
                  width: 48,
                  child: _dragHandle(
                    axis: Axis.horizontal,
                    color: cs.outline,
                    onDrag: (d) {
                      final v = ((right - d.delta.dx) / w).clamp(0.0, 0.35);
                      onChanged(prefs.copyWith(rightMargin: v));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _deadZone(ColorScheme cs, String label) {
    if (label == '0%') return const SizedBox.shrink();
    return ColoredBox(
      color: cs.errorContainer.withValues(alpha: 0.4),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: cs.onErrorContainer,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _gestureArea({
    required Color bgColor,
    required Color fgColor,
    required IconData icon,
    required String percent,
    required bool isLeft,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(!isLeft ? 24 : 0),
        right: Radius.circular(isLeft ? 24 : 0),
      ),
      child: ColoredBox(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: fgColor),
              const SizedBox(height: 2),
              Text(
                percent,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle({
    required Axis axis,
    required ValueChanged<DragUpdateDetails> onDrag,
    required Color color,
  }) {
    final isHorizontal = axis == Axis.horizontal;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: onDrag,
      child: Center(
        child: Container(
          width: isHorizontal ? 4 : 32,
          height: isHorizontal ? 32 : 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
