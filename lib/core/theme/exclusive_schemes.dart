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
};
