import 'package:flutter/material.dart';
import 'package:shonenx/shared/widgets/focusable_tap.dart';

class HeaderBaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final bool focusable;
  final bool autofocus;

  const HeaderBaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(16.0),
    this.focusable = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius =
        (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
            const BorderRadius.all(Radius.circular(20.0)); // Use a slightly larger, bolder radius for home
    final resolvedRadius =
        borderRadius.resolve(Directionality.of(context));

    final inkChild = Ink(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    Widget content;
    if (onTap != null && focusable) {
      content = FocusableTap(
        onTap: onTap,
        autofocus: autofocus,
        borderRadius: resolvedRadius,
        child: inkChild,
      );
    } else if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        canRequestFocus: false,
        child: inkChild,
      );
    } else {
      content = inkChild;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0, // We'll use gradients/borders instead of heavy shadows
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple respects the border radius
      child: content,
    );
  }
}
