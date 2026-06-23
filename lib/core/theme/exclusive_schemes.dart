import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class ExclusiveSchemeData {
  final String name;
  final String description;
  final FlexSchemeColor light;
  final FlexSchemeColor dark;

  const ExclusiveSchemeData({
    required this.name,
    required this.description,
    required this.light,
    required this.dark,
  });
}

const Map<String, ExclusiveSchemeData> exclusiveSchemes = {
  'midnight_tokyo': ExclusiveSchemeData(
    name: 'Midnight Tokyo',
    description: 'Neon-lit streets at night',
    light: FlexSchemeColor(
      primary: Color(0xFF6C3CE1),
      primaryContainer: Color(0xFFE8DEFF),
      secondary: Color(0xFFE91E8C),
      secondaryContainer: Color(0xFFFFD8EE),
      tertiary: Color(0xFF00BCD4),
      tertiaryContainer: Color(0xFFB2EBF2),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFB794F6),
      primaryContainer: Color(0xFF4A1DB8),
      secondary: Color(0xFFFF6EC7),
      secondaryContainer: Color(0xFF99004D),
      tertiary: Color(0xFF4DD0E1),
      tertiaryContainer: Color(0xFF006874),
    ),
  ),

  'arctic_aurora': ExclusiveSchemeData(
    name: 'Arctic Aurora',
    description: 'Northern lights over ice',
    light: FlexSchemeColor(
      primary: Color(0xFF0D7C5F),
      primaryContainer: Color(0xFFA7F3D0),
      secondary: Color(0xFF2563EB),
      secondaryContainer: Color(0xFFBFDBFE),
      tertiary: Color(0xFF7C3AED),
      tertiaryContainer: Color(0xFFDDD6FE),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF34D399),
      primaryContainer: Color(0xFF065F46),
      secondary: Color(0xFF60A5FA),
      secondaryContainer: Color(0xFF1E40AF),
      tertiary: Color(0xFFA78BFA),
      tertiaryContainer: Color(0xFF5B21B6),
    ),
  ),

  'sakura_bloom': ExclusiveSchemeData(
    name: 'Sakura Bloom',
    description: 'Cherry blossoms in spring',
    light: FlexSchemeColor(
      primary: Color(0xFFDB2777),
      primaryContainer: Color(0xFFFCE7F3),
      secondary: Color(0xFFF472B6),
      secondaryContainer: Color(0xFFFBCFE8),
      tertiary: Color(0xFFBE185D),
      tertiaryContainer: Color(0xFFFDA4AF),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFF9A8D4),
      primaryContainer: Color(0xFF9D174D),
      secondary: Color(0xFFFBCFE8),
      secondaryContainer: Color(0xFF831843),
      tertiary: Color(0xFFFDA4AF),
      tertiaryContainer: Color(0xFF9F1239),
    ),
  ),

  'volcanic_ember': ExclusiveSchemeData(
    name: 'Volcanic Ember',
    description: 'Lava flowing through obsidian',
    light: FlexSchemeColor(
      primary: Color(0xFFDC2626),
      primaryContainer: Color(0xFFFEE2E2),
      secondary: Color(0xFFEA580C),
      secondaryContainer: Color(0xFFFFEDD5),
      tertiary: Color(0xFFCA8A04),
      tertiaryContainer: Color(0xFFFEF9C3),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFCA5A5),
      primaryContainer: Color(0xFF991B1B),
      secondary: Color(0xFFFDBA74),
      secondaryContainer: Color(0xFF9A3412),
      tertiary: Color(0xFFFDE047),
      tertiaryContainer: Color(0xFF854D0E),
    ),
  ),

  'deep_ocean': ExclusiveSchemeData(
    name: 'Deep Ocean',
    description: 'Abyssal depths and bioluminescence',
    light: FlexSchemeColor(
      primary: Color(0xFF1E3A5F),
      primaryContainer: Color(0xFFD1E5F7),
      secondary: Color(0xFF0891B2),
      secondaryContainer: Color(0xFFCFFAFE),
      tertiary: Color(0xFF0E7490),
      tertiaryContainer: Color(0xFFA5F3FC),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF7DD3FC),
      primaryContainer: Color(0xFF0C4A6E),
      secondary: Color(0xFF22D3EE),
      secondaryContainer: Color(0xFF155E75),
      tertiary: Color(0xFF67E8F9),
      tertiaryContainer: Color(0xFF164E63),
    ),
  ),

  'golden_hour': ExclusiveSchemeData(
    name: 'Golden Hour',
    description: 'Warm sunset over the horizon',
    light: FlexSchemeColor(
      primary: Color(0xFFB45309),
      primaryContainer: Color(0xFFFDE68A),
      secondary: Color(0xFFD97706),
      secondaryContainer: Color(0xFFFEF3C7),
      tertiary: Color(0xFF92400E),
      tertiaryContainer: Color(0xFFFCD34D),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFBBF24),
      primaryContainer: Color(0xFF78350F),
      secondary: Color(0xFFFCD34D),
      secondaryContainer: Color(0xFF92400E),
      tertiary: Color(0xFFF59E0B),
      tertiaryContainer: Color(0xFF78350F),
    ),
  ),

  'cyber_mint': ExclusiveSchemeData(
    name: 'Cyber Mint',
    description: 'Futuristic mint-green interface',
    light: FlexSchemeColor(
      primary: Color(0xFF059669),
      primaryContainer: Color(0xFFD1FAE5),
      secondary: Color(0xFF0D9488),
      secondaryContainer: Color(0xFFCCFBF1),
      tertiary: Color(0xFF14B8A6),
      tertiaryContainer: Color(0xFF99F6E4),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF6EE7B7),
      primaryContainer: Color(0xFF065F46),
      secondary: Color(0xFF5EEAD4),
      secondaryContainer: Color(0xFF115E59),
      tertiary: Color(0xFF2DD4BF),
      tertiaryContainer: Color(0xFF134E4A),
    ),
  ),

  'lavender_dusk': ExclusiveSchemeData(
    name: 'Lavender Dusk',
    description: 'Twilight purple haze',
    light: FlexSchemeColor(
      primary: Color(0xFF7C3AED),
      primaryContainer: Color(0xFFEDE9FE),
      secondary: Color(0xFFA855F7),
      secondaryContainer: Color(0xFFF3E8FF),
      tertiary: Color(0xFF6366F1),
      tertiaryContainer: Color(0xFFE0E7FF),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFC4B5FD),
      primaryContainer: Color(0xFF5B21B6),
      secondary: Color(0xFFD8B4FE),
      secondaryContainer: Color(0xFF7E22CE),
      tertiary: Color(0xFFA5B4FC),
      tertiaryContainer: Color(0xFF3730A3),
    ),
  ),

  'anime_stream': ExclusiveSchemeData(
    name: 'Animestream',
    description:
        'Minimal lime-accent theme from Animestream\n ~ by @frostnova721',
    light: FlexSchemeColor(
      primary: Color(0xFFCAF979),
      primaryContainer: Color(0xFFEAFCC8),
      secondary: Color(0xFFB8E85F),
      secondaryContainer: Color(0xFFF3FFD9),
      tertiary: Color(0xFF94C93D),
      tertiaryContainer: Color(0xFFE4F7BE),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFCAF979),
      primaryContainer: Color(0xFF3D4D18),
      secondary: Color(0xFFB8E85F),
      secondaryContainer: Color(0xFF2F3A13),
      tertiary: Color(0xFFA7DB4E),
      tertiaryContainer: Color(0xFF26310E),
    ),
  ),

  'metallic_black': ExclusiveSchemeData(
    name: 'Metallic Black',
    description:
        'Metallic blacks with stark, high-contrast silver/neon accents.',
    light: FlexSchemeColor(
      primary: Color(0xFF1E1E1E),
      primaryContainer: Color(0xFFE0E0E0),
      secondary: Color(0xFF424242),
      secondaryContainer: Color(0xFFF5F5F5),
      tertiary: Color(0xFF00E5FF),
      tertiaryContainer: Color(0xFFB2EBF2),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFE0E0E0),
      primaryContainer: Color(0xFF121212),
      secondary: Color(0xFF9E9E9E),
      secondaryContainer: Color(0xFF212121),
      tertiary: Color(0xFF00E5FF),
      tertiaryContainer: Color(0xFF003D4D),
    ),
  ),

  'crimson_forge': ExclusiveSchemeData(
    name: 'Crimson Forge',
    description: 'Rich reds and deep crimsons forged in fire.',
    light: FlexSchemeColor(
      primary: Color(0xFFB71C1C),
      primaryContainer: Color(0xFFFFCDD2),
      secondary: Color(0xFFD32F2F),
      secondaryContainer: Color(0xFFFFEBEE),
      tertiary: Color(0xFFFF8F00),
      tertiaryContainer: Color(0xFFFFECB3),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFF5252),
      primaryContainer: Color(0xFF4A0000),
      secondary: Color(0xFFFF8A80),
      secondaryContainer: Color(0xFF2B0000),
      tertiary: Color(0xFFFFB300),
      tertiaryContainer: Color(0xFF4D3300),
    ),
  ),

  'void_walker': ExclusiveSchemeData(
    name: 'Void Walker',
    description: 'Electric light cutting through deep space',
    light: FlexSchemeColor(
      primary: Color(0xFF1B2A6B),
      primaryContainer: Color(0xFFD4DCFF),
      secondary: Color(0xFF0097A7),
      secondaryContainer: Color(0xFFB2EFF8),
      tertiary: Color(0xFF6200EA),
      tertiaryContainer: Color(0xFFEAD5FF),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF82B4FF),
      primaryContainer: Color(0xFF0D1854),
      secondary: Color(0xFF00E5FF),
      secondaryContainer: Color(0xFF003D4D),
      tertiary: Color(0xFFCE93FF),
      tertiaryContainer: Color(0xFF3D0080),
    ),
  ),

  'blood_moon': ExclusiveSchemeData(
    name: 'Blood Moon',
    description: 'A crimson moon rises over a silent world',
    light: FlexSchemeColor(
      primary: Color(0xFF8B0000),
      primaryContainer: Color(0xFFFFD6D6),
      secondary: Color(0xFF6D1515),
      secondaryContainer: Color(0xFFF5C0C0),
      tertiary: Color(0xFFC0392B),
      tertiaryContainer: Color(0xFFFDECEA),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFF5252),
      primaryContainer: Color(0xFF5C0000),
      secondary: Color(0xFFFF8A80),
      secondaryContainer: Color(0xFF3E0000),
      tertiary: Color(0xFFFFAB40),
      tertiaryContainer: Color(0xFF5D3100),
    ),
  ),

  'synthwave': ExclusiveSchemeData(
    name: 'Synthwave',
    description: 'Retro neon highways and endless night drives',
    light: FlexSchemeColor(
      primary: Color(0xFFC2185B),
      primaryContainer: Color(0xFFFCE4EC),
      secondary: Color(0xFF7B1FA2),
      secondaryContainer: Color(0xFFF3E5F5),
      tertiary: Color(0xFF0097A7),
      tertiaryContainer: Color(0xFFE0F7FA),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFF80AB),
      primaryContainer: Color(0xFF880E4F),
      secondary: Color(0xFFCE93D8),
      secondaryContainer: Color(0xFF4A148C),
      tertiary: Color(0xFF80DEEA),
      tertiaryContainer: Color(0xFF006064),
    ),
  ),

  'phantom': ExclusiveSchemeData(
    name: 'Phantom',
    description: 'Ghost light bleeding through a dark veil',
    light: FlexSchemeColor(
      primary: Color(0xFF4527A0),
      primaryContainer: Color(0xFFEDE7F6),
      secondary: Color(0xFF37474F),
      secondaryContainer: Color(0xFFECEFF1),
      tertiary: Color(0xFF6A1B9A),
      tertiaryContainer: Color(0xFFF3E5F5),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFB39DDB),
      primaryContainer: Color(0xFF1A0533),
      secondary: Color(0xFF90A4AE),
      secondaryContainer: Color(0xFF0D1B1E),
      tertiary: Color(0xFFCE93D8),
      tertiaryContainer: Color(0xFF2D0041),
    ),
  ),

  'toxic': ExclusiveSchemeData(
    name: 'Toxic',
    description: 'Acid green burning through the dark',
    light: FlexSchemeColor(
      primary: Color(0xFF33691E),
      primaryContainer: Color(0xFFCCFF90),
      secondary: Color(0xFF558B2F),
      secondaryContainer: Color(0xFFDCEDC8),
      tertiary: Color(0xFFF57F17),
      tertiaryContainer: Color(0xFFFFF8E1),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFB2FF59),
      primaryContainer: Color(0xFF1B5E20),
      secondary: Color(0xFFCCFF90),
      secondaryContainer: Color(0xFF1B3A0E),
      tertiary: Color(0xFFFFD740),
      tertiaryContainer: Color(0xFF3D2B00),
    ),
  ),

  'rose_ash': ExclusiveSchemeData(
    name: 'Rose Ash',
    description: 'Faded roses pressed between old pages',
    light: FlexSchemeColor(
      primary: Color(0xFFA1616A),
      primaryContainer: Color(0xFFF7DDE0),
      secondary: Color(0xFF8D6E63),
      secondaryContainer: Color(0xFFEFEBE9),
      tertiary: Color(0xFFC48B9F),
      tertiaryContainer: Color(0xFFFCE4EC),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFFADB6),
      primaryContainer: Color(0xFF5C1E27),
      secondary: Color(0xFFBCAAA4),
      secondaryContainer: Color(0xFF3E2723),
      tertiary: Color(0xFFF48FB1),
      tertiaryContainer: Color(0xFF6D1B3B),
    ),
  ),

  'cobalt_rush': ExclusiveSchemeData(
    name: 'Cobalt Rush',
    description: 'Pure saturated blue at maximum velocity',
    light: FlexSchemeColor(
      primary: Color(0xFF1565C0),
      primaryContainer: Color(0xFFBBDEFB),
      secondary: Color(0xFF0277BD),
      secondaryContainer: Color(0xFFE1F5FE),
      tertiary: Color(0xFF00695C),
      tertiaryContainer: Color(0xFFE0F2F1),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF64B5F6),
      primaryContainer: Color(0xFF0D3B7A),
      secondary: Color(0xFF4FC3F7),
      secondaryContainer: Color(0xFF013654),
      tertiary: Color(0xFF4DB6AC),
      tertiaryContainer: Color(0xFF004D40),
    ),
  ),

  'jade_palace': ExclusiveSchemeData(
    name: 'Jade Palace',
    description: 'Imperial jade and ancient gold',
    light: FlexSchemeColor(
      primary: Color(0xFF00695C),
      primaryContainer: Color(0xFFA7FFEB),
      secondary: Color(0xFFB8860B),
      secondaryContainer: Color(0xFFFFF8DC),
      tertiary: Color(0xFF2E7D32),
      tertiaryContainer: Color(0xFFC8E6C9),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF1DE9B6),
      primaryContainer: Color(0xFF003D33),
      secondary: Color(0xFFFFD54F),
      secondaryContainer: Color(0xFF4D3800),
      tertiary: Color(0xFF69F0AE),
      tertiaryContainer: Color(0xFF1B4D23),
    ),
  ),

  'solar_punk': ExclusiveSchemeData(
    name: 'Solar Punk',
    description: 'Green cities and amber skies of tomorrow',
    light: FlexSchemeColor(
      primary: Color(0xFF558B2F),
      primaryContainer: Color(0xFFDCEDC8),
      secondary: Color(0xFFF9A825),
      secondaryContainer: Color(0xFFFFF9C4),
      tertiary: Color(0xFF00838F),
      tertiaryContainer: Color(0xFFE0F7FA),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFAED581),
      primaryContainer: Color(0xFF1B3A0E),
      secondary: Color(0xFFFFD54F),
      secondaryContainer: Color(0xFF4A3000),
      tertiary: Color(0xFF4DD0E1),
      tertiaryContainer: Color(0xFF00363D),
    ),
  ),

  'abyss': ExclusiveSchemeData(
    name: 'Abyss',
    description: 'The deepest dark, barely a colour remains',
    light: FlexSchemeColor(
      primary: Color(0xFF1A237E),
      primaryContainer: Color(0xFFC5CAE9),
      secondary: Color(0xFF283593),
      secondaryContainer: Color(0xFFE8EAF6),
      tertiary: Color(0xFF4527A0),
      tertiaryContainer: Color(0xFFEDE7F6),
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF9FA8DA),
      primaryContainer: Color(0xFF0D0D1A),
      secondary: Color(0xFF7986CB),
      secondaryContainer: Color(0xFF0A0A14),
      tertiary: Color(0xFFB39DDB),
      tertiaryContainer: Color(0xFF120820),
    ),
  ),
};
