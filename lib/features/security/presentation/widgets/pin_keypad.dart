import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometricButton;
  final double buttonSize;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onBiometricPressed,
    this.showBiometricButton = false,
    this.buttonSize = 72,
  });

  Widget _buildDigitButton(BuildContext context, String digit) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onDigitPressed(digit);
        },
        splashColor: cs.primary.withValues(alpha: 0.15),
        highlightColor: cs.primary.withValues(alpha: 0.08),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onLongPress: onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                onLongPress();
              }
            : null,
        splashColor: cs.primary.withValues(alpha: 0.15),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(child: icon),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton(context, '1'),
              _buildDigitButton(context, '2'),
              _buildDigitButton(context, '3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton(context, '4'),
              _buildDigitButton(context, '5'),
              _buildDigitButton(context, '6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton(context, '7'),
              _buildDigitButton(context, '8'),
              _buildDigitButton(context, '9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Biometric or empty
              if (showBiometricButton && onBiometricPressed != null)
                _buildActionButton(
                  context: context,
                  icon: Icon(
                    Icons.fingerprint_rounded,
                    size: 30,
                    color: cs.primary,
                  ),
                  onTap: onBiometricPressed!,
                )
              else
                SizedBox(width: buttonSize, height: buttonSize),

              _buildDigitButton(context, '0'),

              // Delete button
              _buildActionButton(
                context: context,
                icon: Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: cs.onSurfaceVariant,
                ),
                onTap: onDeletePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
