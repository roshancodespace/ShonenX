import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';

class PlayerGestureOverlay extends ConsumerStatefulWidget {
  final VoidCallback onToggleControls;
  final VoidCallback? onHideControls;
  final VoidCallback? onRightClick;
  final void Function(Duration) onSeek;
  final void Function(double) onSetSpeed;
  final double baseSpeed;

  const PlayerGestureOverlay({
    super.key,
    required this.onToggleControls,
    this.onHideControls,
    this.onRightClick,
    required this.onSeek,
    required this.onSetSpeed,
    this.baseSpeed = 1.0,
  });

  @override
  ConsumerState<PlayerGestureOverlay> createState() =>
      _PlayerGestureOverlayState();
}

class _PlayerGestureOverlayState extends ConsumerState<PlayerGestureOverlay> {
  int _lastTapTime = 0;
  int _accumulatedSeekSeconds = 0;
  Timer? _seekAccumulationTimer;

  bool _isLeftSwipe = false;
  bool _isDragging = false;
  double _brightness = 0.5;
  double _volume = 0.5;

  bool _isSpeedScrubbing = false;
  double _currentSpeed = 2.0;
  double _speedDragStartY = 0.0;

  double _initialVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _initializeSystemLevels();
  }

  Future<void> _initializeSystemLevels() async {
    try {
      VolumeController.instance.showSystemUI = false;
      _brightness = await ScreenBrightness.instance.application;
      _volume = await VolumeController.instance.getVolume();
      _initialVolume = _volume;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _triggerSeek(int seconds) {
    widget.onSeek(Duration(seconds: seconds));
    setState(() {
      _accumulatedSeekSeconds += seconds;
    });

    _seekAccumulationTimer?.cancel();
    _seekAccumulationTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _accumulatedSeekSeconds = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _seekAccumulationTimer?.cancel();
    try {
      if (Platform.isAndroid) {
        ScreenBrightness.instance.resetApplicationScreenBrightness();
      }
      VolumeController.instance.setVolume(_initialVolume);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(playerPrefsProvider.select((s) => s.gesturePrefs));
    final cs = Theme.of(context).colorScheme;
    final isDraggingVolume = prefs.swapVolumeAndBrightness
        ? _isLeftSwipe
        : !_isLeftSwipe;
    final dragValue = isDraggingVolume ? _volume : _brightness;

    String speedText = _currentSpeed.toStringAsFixed(2);
    if (speedText.endsWith('.00')) {
      speedText = speedText.substring(0, speedText.length - 3);
    } else if (speedText.endsWith('0')) {
      speedText = speedText.substring(0, speedText.length - 1);
    }
    speedText += 'x';

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final activeWidth = constraints.maxWidth;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onSecondaryTapUp: (_) => widget.onRightClick?.call(),
                onTapUp: (details) {
                  final now = DateTime.now().millisecondsSinceEpoch;

                  if (!prefs.enableGestures) {
                    widget.onToggleControls();
                    return;
                  }

                  final dx = details.localPosition.dx;
                  final isLeft = dx < activeWidth * prefs.doubleTapWidth;
                  final isRight =
                      dx > activeWidth * (1.0 - prefs.doubleTapWidth);

                  if (_accumulatedSeekSeconds != 0) {
                    if (isLeft) {
                      _triggerSeek(-10);
                      return;
                    } else if (isRight) {
                      _triggerSeek(10);
                      return;
                    }
                  }

                  if (now - _lastTapTime < 300) {
                    if (isLeft) {
                      _triggerSeek(-10);
                      widget.onHideControls?.call();
                    } else if (isRight) {
                      _triggerSeek(10);
                      widget.onHideControls?.call();
                    } else {
                      widget.onToggleControls();
                    }
                    _lastTapTime = 0;
                  } else {
                    _lastTapTime = now;
                    widget.onToggleControls();
                  }
                },
                onVerticalDragStart: !prefs.enableGestures
                    ? null
                    : (details) {
                        final dx = details.localPosition.dx;
                        final dy = details.localPosition.dy;
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;

                        if (dy < height * prefs.topMargin ||
                            dy > height * (1.0 - prefs.bottomMargin) ||
                            dx < width * prefs.leftMargin ||
                            dx > width * (1.0 - prefs.rightMargin)) {
                          return;
                        }

                        widget.onHideControls?.call();

                        bool isLeft = dx < width * prefs.leftWidth;
                        bool isRight = dx > width * (1.0 - prefs.rightWidth);

                        if (isLeft || isRight) {
                          setState(() {
                            _isDragging = true;
                            _isLeftSwipe = isLeft;
                          });
                        }
                      },
                onVerticalDragUpdate: !prefs.enableGestures
                    ? null
                    : (details) {
                        if (!_isDragging) return;

                        setState(() {
                          final sensitivity =
                              MediaQuery.of(context).size.height / 1.5;
                          final delta = -details.delta.dy / sensitivity;

                          final changeVolume = prefs.swapVolumeAndBrightness
                              ? _isLeftSwipe
                              : !_isLeftSwipe;

                          if (changeVolume) {
                            _volume = (_volume + delta).clamp(0.0, 1.0);
                            VolumeController.instance.setVolume(_volume);
                          } else {
                            _brightness = (_brightness + delta).clamp(0.0, 1.0);
                            ScreenBrightness.instance
                                .setApplicationScreenBrightness(_brightness);
                          }
                        });
                      },
                onVerticalDragEnd: !prefs.enableGestures
                    ? null
                    : (details) {
                        if (!_isDragging) return;
                        setState(() {
                          _isDragging = false;
                        });
                      },
                onLongPressStart: !prefs.enableGestures
                    ? null
                    : (details) {
                        final dx = details.localPosition.dx;
                        final dy = details.localPosition.dy;
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;

                        if (dy < height * prefs.topMargin ||
                            dy > height * (1.0 - prefs.bottomMargin) ||
                            dx < width * prefs.leftMargin ||
                            dx > width * (1.0 - prefs.rightMargin)) {
                          return;
                        }

                        if (dx > width * (1.0 - prefs.rightWidth)) {
                          widget.onHideControls?.call();
                          setState(() {
                            _isSpeedScrubbing = true;
                            _currentSpeed = 2.0;
                            _speedDragStartY = details.localPosition.dy;
                          });
                          widget.onSetSpeed(_currentSpeed);
                        }
                      },
                onLongPressMoveUpdate: !prefs.enableGestures
                    ? null
                    : (details) {
                        if (_isSpeedScrubbing) {
                          final delta =
                              _speedDragStartY - details.localPosition.dy;
                          double newSpeed = 2.0 + (delta / 120);
                          newSpeed = (newSpeed * 4).round() / 4.0;
                          newSpeed = newSpeed.clamp(0.25, 3.0);

                          if (newSpeed != _currentSpeed) {
                            setState(() {
                              _currentSpeed = newSpeed;
                            });
                            widget.onSetSpeed(_currentSpeed);
                          }
                        }
                      },
                onLongPressEnd: !prefs.enableGestures
                    ? null
                    : (details) {
                        setState(() {
                          _isSpeedScrubbing = false;
                        });
                        widget.onSetSpeed(widget.baseSpeed);
                      },
              );
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                if (_accumulatedSeekSeconds != 0)
                  AnimatedAlign(
                    alignment: _accumulatedSeekSeconds < 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _accumulatedSeekSeconds != 0 ? 1 : 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: _accumulatedSeekSeconds < 0
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            end: _accumulatedSeekSeconds < 0
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(_accumulatedSeekSeconds),
                          tween: Tween<double>(begin: 0.82, end: 1.0),
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          builder: (context, scale, child) {
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _accumulatedSeekSeconds < 0
                                    ? Icons.fast_rewind_rounded
                                    : Icons.fast_forward_rounded,
                                size: 46,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_accumulatedSeekSeconds > 0 ? "+" : ""}$_accumulatedSeekSeconds seconds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isDragging)
                  Align(
                    alignment: _isLeftSwipe
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              '${(dragValue * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 48,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: dragValue,
                              child: Container(color: cs.primary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Icon(
                            isDraggingVolume
                                ? (_volume <= 0.0
                                      ? Icons.volume_mute_rounded
                                      : (_volume < 0.5
                                            ? Icons.volume_down_rounded
                                            : Icons.volume_up_rounded))
                                : Icons.light_mode_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isSpeedScrubbing)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.speed_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 56,
                              child: Text(
                                speedText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
