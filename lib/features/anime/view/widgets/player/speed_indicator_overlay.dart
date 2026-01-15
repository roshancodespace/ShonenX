import 'dart:ui';
import 'package:flutter/material.dart';

class SpeedIndicatorOverlay extends StatelessWidget {
  final double currentSpeed;

  const SpeedIndicatorOverlay({super.key, required this.currentSpeed});

  @override
  Widget build(BuildContext context) {
    final speeds = [4.0, 3.0, 2.0, 1.5, 1.0, 0.5];
    final closest = speeds.reduce(
      (a, b) => (currentSpeed - a).abs() < (currentSpeed - b).abs() ? a : b,
    );

    return Positioned(
      right: 40,
      top: 0,
      bottom: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Precise Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                '${currentSpeed.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Scale
            Container(
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
                                color: Theme.of(context).colorScheme.primary,
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
          ],
        ),
      ),
    );
  }
}
