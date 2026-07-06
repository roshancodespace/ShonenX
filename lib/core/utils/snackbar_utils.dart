import 'package:flutter/material.dart';

class SnackbarUtils {
  static OverlayEntry? _currentSnackbar;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final cs = Theme.of(context).colorScheme;

    _currentSnackbar?.remove();
    _currentSnackbar = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isError
                    ? cs.errorContainer
                    : (isSuccess ? cs.primaryContainer : cs.inverseSurface),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? cs.onErrorContainer
                      : (isSuccess
                            ? cs.onPrimaryContainer
                            : cs.onInverseSurface),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentSnackbar = entry;
    overlay.insert(entry);
    Future.delayed(duration, () {
      if (_currentSnackbar == entry && entry.mounted) {
        entry.remove();
        _currentSnackbar = null;
      }
    });
  }

  static void dismissCurrent() {
    _currentSnackbar?.remove();
    _currentSnackbar = null;
  }
}
