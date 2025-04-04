import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

class OverlayManager {
  OverlayEntry? _overlayEntry;
  Timer? _overlayTimer;

  void showAdjustmentOverlay(BuildContext context,
      {required bool isBrightness, required double value}) {
    _overlayTimer?.cancel();
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: isBrightness ? 0 : MediaQuery.of(context).size.width / 2,
        right: isBrightness ? MediaQuery.of(context).size.width / 2 : 0,
        bottom: 0,
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBrightness ? Icons.brightness_6 : Icons.volume_up,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      _overlayTimer = Timer(Duration(milliseconds: 800), _removeOverlay);
    }
  }

  void showSeekIndicator(BuildContext context, {required bool isForward}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: isForward ? MediaQuery.of(context).size.width / 2 : 0,
        right: isForward ? 0 : MediaQuery.of(context).size.width / 2,
        bottom: 0,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 200),
          onEnd: () => Future.delayed(Duration(milliseconds: 300), () {
            if (context.mounted) overlayEntry.remove();
          }),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.0),
                ],
                begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
                end: isForward ? Alignment.centerLeft : Alignment.centerRight,
              ),
            ),
            child: Center(
              child: Icon(
                isForward ? Iconsax.forward : Iconsax.backward,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void dispose() {
    _overlayTimer?.cancel();
    _removeOverlay();
  }
}
