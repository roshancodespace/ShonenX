import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Floating watch button widget
class WatchButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const WatchButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final navHeight = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 16 + navHeight,
      left: 16,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        label: Text(
          'Watch Now',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Icon(Iconsax.play_circle),
      ),
    );
  }
}
