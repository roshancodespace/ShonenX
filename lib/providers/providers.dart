import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_user.dart';
import 'package:shonenx/providers/anilist/anilist_medialist_provider.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';
import 'package:shonenx/providers/homepage_provider.dart';
import 'package:shonenx/providers/selected_provider.dart';
import 'package:shonenx/providers/watch_providers.dart';
import 'package:shonenx/screens/settings/appearance/theme_screen.dart';
import 'package:shonenx/screens/settings/appearance/ui_screen.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';

/// This file centralizes all providers in the application for easier management
/// and to avoid circular dependencies.

// ============= Service Providers =============

/// Provider for AnilistService to enable dependency injection
final anilistServiceProvider = Provider<AnilistService>((ref) => AnilistService());

// ============= User & Authentication Providers =============

/// Re-export userProvider from anilist_user_provider.dart
/// See [UserNotifier] for implementation details
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

// ============= Anime List Providers =============

/// Re-export animeListProvider from anilist_medialist_provider.dart
/// See [AnimeListNotifier] for implementation details
final animeListProvider = StateNotifierProvider<AnimeListNotifier, AnimeListState>((ref) {
  final userState = ref.watch(userProvider);

  if (userState == null || userState.accessToken.isEmpty || userState.id == null) {
    return AnimeListNotifier(
      anilistService: ref.watch(anilistServiceProvider),
      accessToken: '',
      userId: '',
    );
  }

  return AnimeListNotifier(
    anilistService: ref.watch(anilistServiceProvider),
    accessToken: userState.accessToken,
    userId: userState.id.toString(),
  );
});

// ============= Settings Providers =============

/// Re-export themeSettingsProvider from theme_screen.dart
/// See [ThemeSettingsNotifier] for implementation details
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsState>((ref) {
  return ThemeSettingsNotifier()..initializeSettings();
});

/// Re-export uiSettingsProvider from ui_screen.dart
/// See [UISettingsNotifier] for implementation details
final uiSettingsProvider = StateNotifierProvider<UISettingsNotifier, UISettingsState>((ref) {
  return UISettingsNotifier();
});

/// Re-export playerSettingsProvider from player_screen.dart
/// See [PlayerSettingsNotifier] for implementation details
final playerSettingsProvider = StateNotifierProvider<PlayerSettingsNotifier, PlayerSettingsState>((ref) {
  return PlayerSettingsNotifier();
});

// ============= UI State Providers =============

/// Provider for selected category in watchlist screen
final selectedCategoryProvider = StateProvider<String>((ref) => 'CURRENT');

/// Provider for sort option in watchlist and browse screens
final sortOptionProvider = StateProvider<String>((ref) => 'Title');

/// Provider for genre filter in watchlist screen
final filterGenreProvider = StateProvider<String?>((ref) => null);

/// Provider for format filter in browse screen
final filterFormatProvider = StateProvider<String?>((ref) => null);

/// Provider for loading state of cards, indexed by ID
final cardLoadingProvider = StateProvider.family<bool, String>((ref, id) => false);

/// Provider for loading state of continue watching cards, indexed by position
final continueWatchingLoadingProvider = StateProvider.family<bool, int>((ref, index) => false);
