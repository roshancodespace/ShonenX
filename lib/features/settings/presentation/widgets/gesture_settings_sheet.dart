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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 560;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              isWide ? 24 : 16,
              isWide ? 16 : 8,
              isWide ? 24 : 16,
              isWide ? 28 : 20,
            ),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _GesturePreview(prefs: prefs, isWide: true),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 6,
                        child: _SliderList(
                          prefs: prefs,
                          notifier: notifier,
                          isWide: true,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GesturePreview(prefs: prefs, isWide: false),
                      const SizedBox(height: 20),
                      _SliderList(
                        prefs: prefs,
                        notifier: notifier,
                        isWide: false,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _SliderList extends StatelessWidget {
  final GesturePrefs prefs;
  final PlayerPrefsNotifier notifier;
  final bool isWide;

  const _SliderList({
    required this.prefs,
    required this.notifier,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelW = isWide ? 110.0 : 100.0;
    final pctW = isWide ? 36.0 : 32.0;
    final fs = isWide ? 12.5 : 12.0;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel('Dead Zones', isWide: isWide),
          _row(
            context,
            'Top',
            prefs.topMargin,
            0.4,
            labelW,
            pctW,
            fs,
            (v) => notifier.updateGesturePrefs(prefs.copyWith(topMargin: v)),
          ),
          _row(
            context,
            'Bottom',
            prefs.bottomMargin,
            0.4,
            labelW,
            pctW,
            fs,
            (v) => notifier.updateGesturePrefs(prefs.copyWith(bottomMargin: v)),
          ),
          _row(
            context,
            'Left',
            prefs.leftMargin,
            0.4,
            labelW,
            pctW,
            fs,
            (v) => notifier.updateGesturePrefs(prefs.copyWith(leftMargin: v)),
          ),
          _row(
            context,
            'Right',
            prefs.rightMargin,
            0.4,
            labelW,
            pctW,
            fs,
            (v) => notifier.updateGesturePrefs(prefs.copyWith(rightMargin: v)),
          ),
          SizedBox(height: isWide ? 12 : 8),
          _SectionLabel('Gesture Widths', isWide: isWide),
          _row(
            context,
            'Left',
            prefs.leftWidth,
            (1.0 - prefs.rightWidth - prefs.leftMargin - prefs.rightMargin)
                .clamp(0.1, 0.8),
            labelW,
            pctW,
            fs,
            (v) => notifier.updateGesturePrefs(prefs.copyWith(leftWidth: v)),
          ),
          _row(
            context,
            'Right',
            prefs.rightWidth,
            (1.0 - prefs.leftWidth - prefs.leftMargin - prefs.rightMargin)
                .clamp(0.1, 0.8),
            labelW,
            pctW,
            fs,
            (v) => notifier.updateGesturePrefs(prefs.copyWith(rightWidth: v)),
          ),
          _row(
            context,
            'Double Tap',
            prefs.doubleTapWidth,
            0.45,
            labelW,
            pctW,
            fs,
            (v) =>
                notifier.updateGesturePrefs(prefs.copyWith(doubleTapWidth: v)),
          ),
          SizedBox(height: isWide ? 10 : 6),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  notifier.updateGesturePrefs(const GesturePrefs()),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                textStyle: TextStyle(fontSize: isWide ? 12.5 : 12),
              ),
              child: const Text('Reset defaults'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value,
    double max,
    double labelW,
    double pctW,
    double fs,
    ValueChanged<double> onChanged,
  ) {
    final cs = Theme.of(context).colorScheme;
    final pct = (value * 100).toInt();
    final atMax = value >= max - 0.01;

    return SizedBox(
      height: isWide ? 36 : 32,
      child: Row(
        children: [
          SizedBox(
            width: labelW,
            child: Text(
              label,
              style: TextStyle(
                fontSize: fs,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: isWide ? 2.5 : 2,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: isWide ? 6.5 : 6,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: isWide ? 13 : 11,
                ),
                activeTrackColor: atMax ? cs.error : cs.primary,
                inactiveTrackColor: cs.outlineVariant,
                thumbColor: atMax ? cs.error : cs.primary,
                overlayColor: (atMax ? cs.error : cs.primary).withValues(
                  alpha: 0.1,
                ),
              ),
              child: Slider.adaptive(
                value: value,
                min: 0,
                max: max,
                divisions: 20,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: pctW,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isWide ? 11.5 : 11,
                fontWeight: FontWeight.w600,
                color: atMax ? cs.error : cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isWide;

  const _SectionLabel(this.text, {required this.isWide});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isWide ? 2 : 1, left: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Preview ──────────────────────────────────────────────────────────────────

class _GesturePreview extends StatelessWidget {
  final GesturePrefs prefs;
  final bool isWide;

  const _GesturePreview({required this.prefs, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeH = (1.0 - prefs.topMargin - prefs.bottomMargin).clamp(0.0, 1.0);
    final safeW = (1.0 - prefs.leftMargin - prefs.rightMargin).clamp(0.0, 1.0);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(isWide ? 12 : 10),
          border: Border.all(color: cs.outlineVariant, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (prefs.topMargin > 0)
              Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: prefs.topMargin,
                  child: ColoredBox(color: cs.error.withValues(alpha: 0.15)),
                ),
              ),
            if (prefs.bottomMargin > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: prefs.bottomMargin,
                  child: ColoredBox(color: cs.error.withValues(alpha: 0.15)),
                ),
              ),
            if (prefs.leftMargin > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: prefs.leftMargin,
                  heightFactor: 1,
                  child: ColoredBox(color: cs.error.withValues(alpha: 0.15)),
                ),
              ),
            if (prefs.rightMargin > 0)
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: prefs.rightMargin,
                  heightFactor: 1,
                  child: ColoredBox(color: cs.error.withValues(alpha: 0.15)),
                ),
              ),
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: safeW,
                heightFactor: safeH,
                child: Stack(
                  children: [
                    _gestureZone(
                      alignment: Alignment.centerLeft,
                      width: prefs.leftWidth,
                      color: Colors.blue.withValues(alpha: 0.18),
                      icon: Icons.light_mode_rounded,
                      label: 'Brightness',
                      labelAlign: Alignment.topLeft,
                    ),
                    _gestureZone(
                      alignment: Alignment.centerRight,
                      width: prefs.rightWidth,
                      color: Colors.green.withValues(alpha: 0.18),
                      icon: Icons.volume_up_rounded,
                      label: 'Volume',
                      labelAlign: Alignment.topRight,
                    ),
                    _tapZone(
                      alignment: Alignment.centerLeft,
                      width: prefs.doubleTapWidth,
                      icon: Icons.replay_10_rounded,
                      label: '−10s',
                      isRight: false,
                    ),
                    _tapZone(
                      alignment: Alignment.centerRight,
                      width: prefs.doubleTapWidth,
                      icon: Icons.forward_10_rounded,
                      label: '+10s',
                      isRight: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gestureZone({
    required Alignment alignment,
    required double width,
    required Color color,
    required IconData icon,
    required String label,
    required Alignment labelAlign,
  }) {
    final iconSize = isWide ? 20.0 : 15.0;
    final fontSize = isWide ? 8.5 : 7.0;
    final padding = isWide ? 8.0 : 5.0;

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: width,
        heightFactor: 1,
        child: Container(
          color: color,
          padding: EdgeInsets.all(padding),
          child: Stack(
            children: [
              Align(
                alignment: labelAlign,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tapZone({
    required Alignment alignment,
    required double width,
    required IconData icon,
    required String label,
    required bool isRight,
  }) {
    final iconSize = isWide ? 11.0 : 8.0;
    final fontSize = isWide ? 8.5 : 7.0;
    final padding = isWide ? 8.0 : 5.0;

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: width,
        heightFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: isRight
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.12))
                  : BorderSide.none,
              right: isRight
                  ? BorderSide.none
                  : BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          padding: EdgeInsets.all(padding),
          child: Align(
            alignment: isRight ? Alignment.bottomRight : Alignment.bottomLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: isRight
                  ? [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      SizedBox(width: isWide ? 3 : 2),
                      Icon(
                        icon,
                        size: iconSize,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ]
                  : [
                      Icon(
                        icon,
                        size: iconSize,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      SizedBox(width: isWide ? 3 : 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
