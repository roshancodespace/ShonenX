import 'dart:async';
import 'package:flutter/material.dart';

class SpeedIndicatorOverlay extends StatefulWidget {
  final double currentSpeed;

  const SpeedIndicatorOverlay({super.key, required this.currentSpeed});

  @override
  State<SpeedIndicatorOverlay> createState() => _SpeedIndicatorOverlayState();
}

class _SpeedIndicatorOverlayState extends State<SpeedIndicatorOverlay> {
  double _opacity = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void didUpdateWidget(covariant SpeedIndicatorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSpeed != oldWidget.currentSpeed) {
      _resetTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() => _opacity = 1.0);
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _opacity = 0.2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final speeds = [4.0, 3.0, 2.0, 1.5, 1.0, 0.5];
    final closest = speeds.reduce(
      (a, b) =>
          (widget.currentSpeed - a).abs() < (widget.currentSpeed - b).abs()
          ? a
          : b,
    );

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Stack(
          children: [
            // Precise Indicator - Top Center
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    '${widget.currentSpeed.toStringAsFixed(2)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            // Scale - Right Side
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Container(
                  width: 50,
                  height: 300,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: speeds.map((speed) {
                      final isSelected = speed == closest;
                      return AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 100),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${speed}x',
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
