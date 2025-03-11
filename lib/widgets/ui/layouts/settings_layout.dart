import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class SettingsLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsLayout({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // final thextTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left_1, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(50),
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface),
        ),
      ),
      body: child,
    );
  }
}
