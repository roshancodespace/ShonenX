import 'package:flutter/material.dart';

class PinDotsIndicator extends StatelessWidget {
  final int pinLength;
  final int enteredLength;
  final bool hasError;
  final String? errorText;

  const PinDotsIndicator({
    super.key,
    this.pinLength = 4,
    required this.enteredLength,
    this.hasError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (index) {
            final isFilled = index < enteredLength;
            final dotColor = hasError
                ? cs.error
                : (isFilled ? cs.primary : cs.surfaceContainerHighest);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? dotColor : Colors.transparent,
                border: Border.all(
                  color: hasError
                      ? cs.error
                      : (isFilled ? cs.primary : cs.outlineVariant),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            errorText!,
            style: TextStyle(
              color: cs.error,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
