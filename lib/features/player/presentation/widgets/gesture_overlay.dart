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
    final theme = Theme.of(context);
    final prefs = ref.watch(playerPrefsProvider.select((s) => s.gesturePrefs));

    String speedText = _currentSpeed.toString();
    if (speedText.endsWith('.0')) {
      speedText = speedText.substring(0, speedText.length - 2);
    }
    speedText += 'x';

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * prefs.topMargin,
              bottom: MediaQuery.of(context).size.height * prefs.bottomMargin,
              left: MediaQuery.of(context).size.width * prefs.leftMargin,
              right: MediaQuery.of(context).size.width * prefs.rightMargin,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final activeWidth = constraints.maxWidth;

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onSecondaryTapUp: (_) => widget.onRightClick?.call(),
                  onTapUp: (details) {
                    final now = DateTime.now().millisecondsSinceEpoch;
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
                  onVerticalDragStart: (details) {
                    widget.onHideControls?.call();
                    final dx = details.localPosition.dx;

                    bool isLeft = dx < activeWidth * prefs.leftWidth;
                    bool isRight = dx > activeWidth * (1.0 - prefs.rightWidth);

                    if (isLeft || isRight) {
                      setState(() {
                        _isDragging = true;
                        _isLeftSwipe = isLeft;
                      });
                    }
                  },
                  onVerticalDragUpdate: (details) {
                    if (!_isDragging) return;

                    setState(() {
                      final sensitivity =
                          MediaQuery.of(context).size.height / 1.5;
                      final delta = -details.delta.dy / sensitivity;

                      if (_isLeftSwipe) {
                        _brightness = (_brightness + delta).clamp(0.0, 1.0);
                        ScreenBrightness.instance
                            .setApplicationScreenBrightness(_brightness);
                      } else {
                        _volume = (_volume + delta).clamp(0.0, 1.0);
                        VolumeController.instance.setVolume(_volume);
                      }
                    });
                  },
                  onVerticalDragEnd: (details) {
                    if (!_isDragging) return;
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  onLongPressStart: (details) {
                    final dx = details.localPosition.dx;

                    if (dx > activeWidth * (1.0 - prefs.rightWidth)) {
                      widget.onHideControls?.call();
                      setState(() {
                        _isSpeedScrubbing = true;
                        _currentSpeed = 2.0;
                        _speedDragStartY = details.localPosition.dy;
                      });
                      widget.onSetSpeed(_currentSpeed);
                    }
                  },
                  onLongPressMoveUpdate: (details) {
                    if (_isSpeedScrubbing) {
                      final delta = _speedDragStartY - details.localPosition.dy;
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
                  onLongPressEnd: (details) {
                    setState(() {
                      _isSpeedScrubbing = false;
                    });
                    widget.onSetSpeed(widget.baseSpeed);
                  },
                );
              },
            ),
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
                  Positioned(
                    bottom: 48,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isLeftSwipe
                                  ? Icons.light_mode_rounded
                                  : (_volume <= 0.0
                                        ? Icons.volume_mute_rounded
                                        : (_volume < 0.5
                                              ? Icons.volume_down_rounded
                                              : Icons.volume_up_rounded)),
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${((_isLeftSwipe ? _brightness : _volume) * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 20,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _SkewedBlocksPainter(
                              value: _isLeftSwipe ? _brightness : _volume,
                              isLeft: _isLeftSwipe,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isSpeedScrubbing)
                  Positioned(
                    bottom: 48,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.speed_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              speedText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 20,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _SkewedBlocksPainter(
                              value:
                                  (_currentSpeed - 0.25) /
                                  2.75, // Normalize 0.25-3.0 to 0.0-1.0
                              isLeft: false, // Start from left for speed
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
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

class _SkewedBlocksPainter extends CustomPainter {
  final double value;
  final bool isLeft;
  final Color color;

  _SkewedBlocksPainter({
    required this.value,
    required this.isLeft,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int totalBlocks = 32;
    const double blockWidth = 8.0;
    const double blockSpacing = 4.0;
    const double skewOffset =
        8.0; // How much the top is shifted right relative to bottom

    final double totalWidth =
        (totalBlocks * blockWidth) +
        ((totalBlocks - 1) * blockSpacing) +
        skewOffset;
    final double startX = (size.width - totalWidth) / 2;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final inactivePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final int activeBlocksCount = (value * totalBlocks).round();

    for (int i = 0; i < totalBlocks; i++) {
      // If it's volume (right swipe), we can fill from left-to-right, or we can just always fill left-to-right.
      // A common pattern is filling from center outwards, or just left-to-right. Let's do left-to-right.
      bool isActive = isLeft
          ? (i < activeBlocksCount) // Fill left-to-right
          : (i >=
                totalBlocks -
                    activeBlocksCount); // Fill right-to-left for volume, or keep it left-to-right. Let's keep it left-to-right for consistency, so i < activeBlocksCount.

      // Actually, standard is left-to-right for all progress bars.
      isActive = i < activeBlocksCount;

      final double blockStartX = startX + i * (blockWidth + blockSpacing);

      final path = Path();
      // Bottom left
      path.moveTo(blockStartX, size.height);
      // Bottom right
      path.lineTo(blockStartX + blockWidth, size.height);
      // Top right (skewed right)
      path.lineTo(blockStartX + blockWidth + skewOffset, 0);
      // Top left (skewed right)
      path.lineTo(blockStartX + skewOffset, 0);
      path.close();

      if (isActive) {
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, activePaint);
      } else {
        canvas.drawPath(path, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkewedBlocksPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.isLeft != isLeft ||
        oldDelegate.color != color;
  }
}
