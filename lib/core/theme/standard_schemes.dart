import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';

enum AppScheme {
  deepBlue,
  redM3,
  sakura,
  greenM3,
  deepPurple,
  mandyRed,
  shadRed,
  teal,
  indigo,
  amber,
  orange,
  cyan,
  espresso,
  slate,
  material,
  custom;

  String get displayName => switch (this) {
    AppScheme.deepBlue => 'Deep Blue',
    AppScheme.redM3 => 'Crimson',
    AppScheme.sakura => 'Sakura',
    AppScheme.greenM3 => 'Emerald',
    AppScheme.deepPurple => 'Purple',
    AppScheme.mandyRed => 'Sunset',
    AppScheme.shadRed => 'Blood Red',
    AppScheme.teal => 'Ocean Teal',
    AppScheme.indigo => 'Indigo Night',
    AppScheme.amber => 'Amber Gold',
    AppScheme.orange => 'Sunset Orange',
    AppScheme.cyan => 'Cyber Cyan',
    AppScheme.espresso => 'Espresso',
    AppScheme.slate => 'Slate Metal',
    AppScheme.material => 'Material Baseline',
    AppScheme.custom => 'Custom',
  };

  String get description => switch (this) {
    AppScheme.deepBlue => 'Deep blue sea with navy and sky blue accents',
    AppScheme.redM3 => 'Material 3 crimson red with rich rose tones',
    AppScheme.sakura => 'Japanese cherry blossom pink and soft rose',
    AppScheme.greenM3 => 'Material 3 forest and emerald greens',
    AppScheme.deepPurple => 'Vibrant purple with lavender highlights',
    AppScheme.mandyRed => 'Warm sunset red and apricot shades',
    AppScheme.shadRed => 'Deep ruby red with sleek dark contrast',
    AppScheme.teal => 'Cool turquoise and cyan waves',
    AppScheme.indigo => 'Midnight indigo and royal blue',
    AppScheme.amber => 'Warm golden amber with bronze touches',
    AppScheme.orange => 'Vibrant citrus orange with fiery tones',
    AppScheme.cyan => 'Electric cyan and neon teal',
    AppScheme.espresso => 'Rich mocha coffee and warm caramel',
    AppScheme.slate => 'Modern industrial slate and steel',
    AppScheme.material => 'Default Material 3 primary palette',
    AppScheme.custom => 'User defined custom color palette',
  };

  Color get seedColor => switch (this) {
    AppScheme.deepBlue => const Color(0xFF1565C0),
    AppScheme.redM3 => const Color(0xFFB3261E),
    AppScheme.sakura => const Color(0xFFCE5B78),
    AppScheme.greenM3 => const Color(0xFF2E6C38),
    AppScheme.deepPurple => const Color(0xFF6750A4),
    AppScheme.mandyRed => const Color(0xFFCD5758),
    AppScheme.shadRed => const Color(0xFF7E1E1E),
    AppScheme.teal => const Color(0xFF00796B),
    AppScheme.indigo => const Color(0xFF303F9F),
    AppScheme.amber => const Color(0xFFFFA000),
    AppScheme.orange => const Color(0xFFE65100),
    AppScheme.cyan => const Color(0xFF0097A7),
    AppScheme.espresso => const Color(0xFF4E342E),
    AppScheme.slate => const Color(0xFF455A64),
    AppScheme.material => const Color(0xFF6750A4),
    AppScheme.custom => const Color(0xFF1565C0),
  };

  AppSchemeColors get colors {
    final seed = seedColor;
    return AppSchemeColors(
      primary: seed,
      primaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.22), const Color(0xFFFFFFFF)),
      secondary: Color.alphaBlend(seed.withValues(alpha: 0.55), const Color(0xFF333333)),
      secondaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.14), const Color(0xFFFFFFFF)),
      tertiary: Color.alphaBlend(seed.withValues(alpha: 0.38), const Color(0xFF888888)),
      tertiaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.10), const Color(0xFFFFFFFF)),
    );
  }
}

class AppSchemeData {
  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final AppSchemeColors light;
  final AppSchemeColors dark;

  const AppSchemeData({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.light,
    required this.dark,
  });

  factory AppSchemeData.fromScheme(AppScheme scheme) {
    final lightColors = scheme.colors;
    final seed = scheme.seedColor;
    final darkColors = AppSchemeColors(
      primary: seed,
      primaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.35), const Color(0xFF000000)),
      secondary: Color.alphaBlend(seed.withValues(alpha: 0.70), const Color(0xFFCCCCCC)),
      secondaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.20), const Color(0xFF1E1E1E)),
      tertiary: Color.alphaBlend(seed.withValues(alpha: 0.50), const Color(0xFFEEEEEE)),
      tertiaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.15), const Color(0xFF1E1E1E)),
    );
    return AppSchemeData(
      id: scheme.name,
      name: scheme.displayName,
      description: scheme.description,
      primary: scheme.seedColor,
      secondary: lightColors.secondary,
      tertiary: lightColors.tertiary,
      light: lightColors,
      dark: darkColors,
    );
  }
}

final Map<AppScheme, AppSchemeData> standardSchemes = {
  for (final scheme in AppScheme.values)
    if (scheme != AppScheme.custom)
      scheme: AppSchemeData.fromScheme(scheme),
};

