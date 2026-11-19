import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/theme/theme_color_resolver.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

class ThemeVariantSwatchPreview extends ConsumerWidget {
  const ThemeVariantSwatchPreview({
    super.key,
    required this.variant,
    required this.isDark,
  });
  final AppThemeVariant variant;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIsDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(themePrefsProvider);
    final resolved = resolveThemeColors(
      prefs,
      brightness: activeIsDark ? Brightness.dark : Brightness.light,
      dynamicColorScheme: prefs.useDynamic ? Theme.of(context).colorScheme : null,
    );

    final Color previewPrimary;
    final Color previewSecondary;
    final Color previewTertiary;

    if (variant == AppThemeVariant.classic) {
      previewPrimary = resolved.primaryKey;
      previewSecondary = resolved.secondaryKey;
      previewTertiary = resolved.tertiaryKey;
    } else {
      final seededScheme = SeedColorScheme.fromSeeds(
        brightness: activeIsDark ? Brightness.dark : Brightness.light,
        primaryKey: resolved.primaryKey,
        secondaryKey: resolved.secondaryKey,
        tertiaryKey: resolved.tertiaryKey,
        variant: variant.flexVariant,
      );
      previewPrimary = seededScheme.primary;
      previewSecondary = seededScheme.secondary;
      previewTertiary = seededScheme.tertiary;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [previewPrimary, previewSecondary, previewTertiary],
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
