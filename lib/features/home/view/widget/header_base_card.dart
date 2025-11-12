import 'package:flutter/material.dart';

class HeaderBaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;

  const HeaderBaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
        BorderRadius.circular(20.0); // Use a slightly larger, bolder radius for home

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0, // We'll use gradients/borders instead of heavy shadows
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple respects the border radius
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}