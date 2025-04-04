import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CenterControls extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  final ThemeData theme;

  const CenterControls({
    super.key,
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on screen dimensions
        final screenWidth = MediaQuery.of(context).size.width;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final baseSize = isLandscape ? screenWidth * 0.1 : screenWidth * 0.15;
        final iconSize = baseSize * 0.4;
        final padding = baseSize * 0.01;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              child: Padding(
                padding: EdgeInsets.all(padding.clamp(8, 16)),
                child: SizedBox(
                  width: baseSize.clamp(48, 64), // Minimum 48 for accessibility
                  height: baseSize.clamp(48, 64),
                  child: Center(
                    child: isBuffering
                        ? CircularProgressIndicator(
                            color: theme.colorScheme.onPrimaryContainer,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                        : Icon(
                            isPlaying ? Iconsax.pause : Iconsax.play5,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: iconSize.clamp(24, 32),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
