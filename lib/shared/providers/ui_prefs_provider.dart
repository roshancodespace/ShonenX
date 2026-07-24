import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

export 'package:shonenx/shared/models/ui_style_enums.dart';

class UiPrefState {
  static const Map<String, dynamic> defaultExperimentalConfig = {
    'enableMetaball': true,
    'interactiveOrb': true,
    'enable3dTilt': true,
    'smoothness': 46.0,
    'distortion': 0.15,
    'magnification': 1.06,
    'chromaticAberration': 0.006,
    'borderSaturation': 1.6,
    'enableLuminousBorder': true,
    'borderGlowIntensity': 0.65,
    'borderWidth': 2.0,
    'cardTintOpacity': 0.10,
    'lensAppearanceTint': 0.13,
    'enableBadgeLens': true,
    'enableCardShadow': false,
  };

  final MediaCardStyle cardStyle;
  final ContinueWatchingStyle continueWatchingStyle;
  final ContinueReadingStyle continueReadingStyle;
  final EpisodeViewMode episodeViewMode;
  final NavBarStyle navBarStyle;
  final Map<String, dynamic> experimentalConfig;
  final Map<String, bool> cardStyleWideModes;
  final bool showCardRatings;
  final bool showCardGenres;
  final bool showCardYear;

  const UiPrefState({
    this.cardStyle = MediaCardStyle.classic,
    this.continueWatchingStyle = ContinueWatchingStyle.classic,
    this.continueReadingStyle = ContinueReadingStyle.classic,
    this.episodeViewMode = EpisodeViewMode.classic,
    this.navBarStyle = NavBarStyle.classic,
    this.experimentalConfig = defaultExperimentalConfig,
    this.cardStyleWideModes = const {},
    this.showCardRatings = true,
    this.showCardGenres = true,
    this.showCardYear = true,
  });

  bool isWideCardMode(String key) => cardStyleWideModes[key] ?? false;

  bool isMediaCardWide(String styleName) => isWideCardMode('media_$styleName');

  bool isContinueWatchingWide(String styleName) =>
      isWideCardMode('cw_$styleName');

  bool isContinueReadingWide(String styleName) =>
      isWideCardMode('cr_$styleName');

  UiPrefState copyWith({
    MediaCardStyle? cardStyle,
    ContinueWatchingStyle? continueWatchingStyle,
    ContinueReadingStyle? continueReadingStyle,
    EpisodeViewMode? episodeViewMode,
    NavBarStyle? navBarStyle,
    Map<String, dynamic>? experimentalConfig,
    Map<String, bool>? cardStyleWideModes,
    bool? showCardRatings,
    bool? showCardGenres,
    bool? showCardYear,
  }) {
    return UiPrefState(
      cardStyle: cardStyle ?? this.cardStyle,
      continueWatchingStyle:
          continueWatchingStyle ?? this.continueWatchingStyle,
      continueReadingStyle: continueReadingStyle ?? this.continueReadingStyle,
      episodeViewMode: episodeViewMode ?? this.episodeViewMode,
      navBarStyle: navBarStyle ?? this.navBarStyle,
      experimentalConfig: experimentalConfig ?? this.experimentalConfig,
      cardStyleWideModes: cardStyleWideModes ?? this.cardStyleWideModes,
      showCardRatings: showCardRatings ?? this.showCardRatings,
      showCardGenres: showCardGenres ?? this.showCardGenres,
      showCardYear: showCardYear ?? this.showCardYear,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardStyle': cardStyle.name,
    'continueWatchingStyle': continueWatchingStyle.name,
    'continueReadingStyle': continueReadingStyle.name,
    'episodeViewMode': episodeViewMode.name,
    'navBarStyle': navBarStyle.name,
    'experimentalConfig': experimentalConfig,
    'cardStyleWideModes': cardStyleWideModes,
    'showCardRatings': showCardRatings,
    'showCardGenres': showCardGenres,
    'showCardYear': showCardYear,
  };

  factory UiPrefState.fromJson(Map<String, dynamic> json) {
    return UiPrefState(
      cardStyle: MediaCardStyle.values.firstWhere(
        (e) => e.name == json['cardStyle'],
        orElse: () => MediaCardStyle.classic,
      ),
      continueWatchingStyle: ContinueWatchingStyle.values.firstWhere(
        (e) => e.name == json['continueWatchingStyle'],
        orElse: () => ContinueWatchingStyle.classic,
      ),
      continueReadingStyle: ContinueReadingStyle.values.firstWhere(
        (e) => e.name == json['continueReadingStyle'],
        orElse: () => ContinueReadingStyle.classic,
      ),
      episodeViewMode: EpisodeViewMode.values.firstWhere(
        (e) => e.name == json['episodeViewMode'],
        orElse: () => EpisodeViewMode.classic,
      ),
      navBarStyle: NavBarStyle.values.firstWhere(
        (e) => e.name == json['navBarStyle'],
        orElse: () => NavBarStyle.classic,
      ),
      experimentalConfig: (json['experimentalConfig'] is Map)
          ? {
              ...defaultExperimentalConfig,
              ...Map<String, dynamic>.from(json['experimentalConfig'] as Map),
            }
          : defaultExperimentalConfig,
      cardStyleWideModes: (json['cardStyleWideModes'] is Map)
          ? Map<String, bool>.from(json['cardStyleWideModes'] as Map)
          : const {},
      showCardRatings: json['showCardRatings'] ?? true,
      showCardGenres: json['showCardGenres'] ?? true,
      showCardYear: json['showCardYear'] ?? true,
    );
  }

  @override
  String toString() =>
      'UiPrefState(cardStyle: $cardStyle, continueWatchingStyle: $continueWatchingStyle, continueReadingStyle: $continueReadingStyle, episodeViewMode: $episodeViewMode, navBarStyle: $navBarStyle, experimentalConfig: $experimentalConfig, cardStyleWideModes: $cardStyleWideModes, showCardRatings: $showCardRatings, showCardGenres: $showCardGenres, showCardYear: $showCardYear)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UiPrefState &&
        other.cardStyle == cardStyle &&
        other.continueWatchingStyle == continueWatchingStyle &&
        other.continueReadingStyle == continueReadingStyle &&
        other.episodeViewMode == episodeViewMode &&
        other.navBarStyle == navBarStyle &&
        other.showCardRatings == showCardRatings &&
        other.showCardGenres == showCardGenres &&
        other.showCardYear == showCardYear &&
        mapEquals(other.experimentalConfig, experimentalConfig) &&
        mapEquals(other.cardStyleWideModes, cardStyleWideModes);
  }

  @override
  int get hashCode => Object.hash(
    cardStyle,
    continueWatchingStyle,
    continueReadingStyle,
    episodeViewMode,
    navBarStyle,
    experimentalConfig,
    cardStyleWideModes,
    showCardRatings,
    showCardGenres,
    showCardYear,
  );
}

class UiPrefsNotifier extends Notifier<UiPrefState> {
  static const _key = 'ui_preferences';
  Timer? _debounce;

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  UiPrefState build() {
    final json = _storage.getString(_key);
    if (json != null) {
      try {
        return UiPrefState.fromJson(jsonDecode(json));
      } catch (_) {}
    }
    return const UiPrefState();
  }

  void updateCardStyle(MediaCardStyle style) {
    state = state.copyWith(cardStyle: style);
    _saveDb();
  }

  void setWideCardMode(String key, bool isWide) {
    state = state.copyWith(
      cardStyleWideModes: {...state.cardStyleWideModes, key: isWide},
    );
    _saveDb();
  }

  void _toggleWideCardMode(String key) {
    final current = state.isWideCardMode(key);
    setWideCardMode(key, !current);
  }

  void toggleMediaCardWide(String styleName) =>
      _toggleWideCardMode('media_$styleName');

  void toggleContinueWatchingWide(String styleName) =>
      _toggleWideCardMode('cw_$styleName');

  void toggleContinueReadingWide(String styleName) =>
      _toggleWideCardMode('cr_$styleName');

  void toggleShowCardRatings() {
    state = state.copyWith(showCardRatings: !state.showCardRatings);
    _saveDb();
  }

  void toggleShowCardGenres() {
    state = state.copyWith(showCardGenres: !state.showCardGenres);
    _saveDb();
  }

  void toggleShowCardYear() {
    state = state.copyWith(showCardYear: !state.showCardYear);
    _saveDb();
  }

  void updateExperimentalConfig(Map<String, dynamic> newValues) {
    state = state.copyWith(
      experimentalConfig: {...state.experimentalConfig, ...newValues},
    );
    _saveDb();
  }

  void updateUiPrefs(UiPrefState Function(UiPrefState) updater) {
    state = updater(state);
    _saveDb();
  }

  void resetExperimentalConfig() {
    state = state.copyWith(
      experimentalConfig: UiPrefState.defaultExperimentalConfig,
    );
    _saveDb();
  }

  void updateContinueWatchingStyle(ContinueWatchingStyle style) {
    state = state.copyWith(continueWatchingStyle: style);
    _saveDb();
  }

  void updateContinueReadingStyle(ContinueReadingStyle style) {
    state = state.copyWith(continueReadingStyle: style);
    _saveDb();
  }

  void updateEpisodeViewMode(EpisodeViewMode mode) {
    state = state.copyWith(episodeViewMode: mode);
    _saveDb();
  }

  void updateNavBarStyle(NavBarStyle style) {
    state = state.copyWith(navBarStyle: style);
    _saveDb();
  }

  void reset() {
    _storage.remove(_key);
    state = const UiPrefState();
  }

  void _saveDb() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final newValue = jsonEncode(state.toJson());
      if (_storage.getString(_key) != newValue) {
        _storage.setString(_key, newValue);
      }
    });
  }
}

final uiPrefsProvider = NotifierProvider<UiPrefsNotifier, UiPrefState>(
  UiPrefsNotifier.new,
);
