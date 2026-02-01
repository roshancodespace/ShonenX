import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class VolumeBrightnessOverlay extends StatefulWidget {
  final bool isVolume;
  final double value;

  const VolumeBrightnessOverlay({
    super.key,
    required this.isVolume,
    required this.value,
  });

  @override
  State<VolumeBrightnessOverlay> createState() =>
      _VolumeBrightnessOverlayState();
}

class _VolumeBrightnessOverlayState extends State<VolumeBrightnessOverlay> {
  double _opacity = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _opacity = 1.0;
  }

  @override
  void didUpdateWidget(covariant VolumeBrightnessOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _show();
    }
  }

  void _show() {
    setState(() => _opacity = 1.0);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _opacity = 0.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_opacity == 0.0) return const SizedBox();

    final isBoosted = widget.isVolume && widget.value > 1.0;
    final displayValue = widget.value.clamp(0.0, 1.25);
    final percent = (displayValue * 100).toInt();

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isVolume
                    ? (percent == 0
                          ? Iconsax.volume_slash
                          : (percent < 50
                                ? Iconsax.volume_low
                                : Iconsax.volume_high))
                    : (percent < 50 ? Iconsax.sun_1 : Iconsax.sun_1),
                color: isBoosted ? Colors.redAccent : Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                width: 8,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: constraints.maxHeight * (displayValue / 1.25),
                          decoration: BoxDecoration(
                            color: isBoosted
                                ? Colors.redAccent
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$percent%',
                style: TextStyle(
                  color: isBoosted ? Colors.redAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
