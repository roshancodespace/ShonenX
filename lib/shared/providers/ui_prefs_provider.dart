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
  final MediaCardStyle cardStyle;
  final ContinueWatchingStyle continueWatchingStyle;
  final ContinueReadingStyle continueReadingStyle;
  final EpisodeViewMode episodeViewMode;
  final NavBarStyle navBarStyle;
  final HomeHeaderStyle homeHeaderStyle;
  final Map<String, bool> cardStyleWideModes;
  final bool showCardRatings;
  final bool showCardGenres;
  final bool showCardYear;
  final bool useNewUi;
  final bool sheetPhysics;

  const UiPrefState({
    this.cardStyle = MediaCardStyle.classic,
    this.continueWatchingStyle = ContinueWatchingStyle.classic,
    this.continueReadingStyle = ContinueReadingStyle.classic,
    this.episodeViewMode = EpisodeViewMode.classic,
    this.navBarStyle = NavBarStyle.classic,
    this.homeHeaderStyle = HomeHeaderStyle.classic,
    this.cardStyleWideModes = const {},
    this.showCardRatings = true,
    this.showCardGenres = true,
    this.showCardYear = true,
    this.useNewUi = false,
    this.sheetPhysics = true,
  });

  bool isWideCardMode(String key) => cardStyleWideModes[key] ?? false;

  bool isMediaCardWide(String styleName) => isWideCardMode('media_$styleName');

  bool isContinueWatchingWide(String styleName) =>
      cardStyleWideModes['cw_$styleName'] ?? true;

  bool isContinueReadingWide(String styleName) =>
      isWideCardMode('cr_$styleName');

  UiPrefState copyWith({
    MediaCardStyle? cardStyle,
    ContinueWatchingStyle? continueWatchingStyle,
    ContinueReadingStyle? continueReadingStyle,
    EpisodeViewMode? episodeViewMode,
    NavBarStyle? navBarStyle,
    HomeHeaderStyle? homeHeaderStyle,
    Map<String, bool>? cardStyleWideModes,
    bool? showCardRatings,
    bool? showCardGenres,
    bool? showCardYear,
    bool? useNewUi,
    bool? sheetPhysics,
  }) {
    return UiPrefState(
      cardStyle: cardStyle ?? this.cardStyle,
      continueWatchingStyle:
          continueWatchingStyle ?? this.continueWatchingStyle,
      continueReadingStyle: continueReadingStyle ?? this.continueReadingStyle,
      episodeViewMode: episodeViewMode ?? this.episodeViewMode,
      navBarStyle: navBarStyle ?? this.navBarStyle,
      homeHeaderStyle: homeHeaderStyle ?? this.homeHeaderStyle,
      cardStyleWideModes: cardStyleWideModes ?? this.cardStyleWideModes,
      showCardRatings: showCardRatings ?? this.showCardRatings,
      showCardGenres: showCardGenres ?? this.showCardGenres,
      showCardYear: showCardYear ?? this.showCardYear,
      useNewUi: useNewUi ?? this.useNewUi,
      sheetPhysics: sheetPhysics ?? this.sheetPhysics,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardStyle': cardStyle.name,
    'continueWatchingStyle': continueWatchingStyle.name,
    'continueReadingStyle': continueReadingStyle.name,
    'episodeViewMode': episodeViewMode.name,
    'navBarStyle': navBarStyle.name,
    'homeHeaderStyle': homeHeaderStyle.name,
    'cardStyleWideModes': cardStyleWideModes,
    'showCardRatings': showCardRatings,
    'showCardGenres': showCardGenres,
    'showCardYear': showCardYear,
    'useNewUi': useNewUi,
    'sheetPhysics': sheetPhysics,
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
      homeHeaderStyle: HomeHeaderStyle.values.firstWhere(
        (e) => e.name == json['homeHeaderStyle'],
        orElse: () => HomeHeaderStyle.classic,
      ),
      cardStyleWideModes: (json['cardStyleWideModes'] is Map)
          ? Map<String, bool>.from(json['cardStyleWideModes'] as Map)
          : const {},
      showCardRatings: json['showCardRatings'] ?? true,
      showCardGenres: json['showCardGenres'] ?? true,
      showCardYear: json['showCardYear'] ?? true,
      useNewUi: json['useNewUi'] ?? false,
      sheetPhysics: json['sheetPhysics'] ?? true,
    );
  }

  @override
  String toString() =>
      'UiPrefState(cardStyle: $cardStyle, continueWatchingStyle: $continueWatchingStyle, continueReadingStyle: $continueReadingStyle, episodeViewMode: $episodeViewMode, navBarStyle: $navBarStyle, homeHeaderStyle: $homeHeaderStyle, cardStyleWideModes: $cardStyleWideModes, showCardRatings: $showCardRatings, showCardGenres: $showCardGenres, showCardYear: $showCardYear, useNewUi: $useNewUi, sheetPhysics: $sheetPhysics)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UiPrefState &&
        other.cardStyle == cardStyle &&
        other.continueWatchingStyle == continueWatchingStyle &&
        other.continueReadingStyle == continueReadingStyle &&
        other.episodeViewMode == episodeViewMode &&
        other.navBarStyle == navBarStyle &&
        other.homeHeaderStyle == homeHeaderStyle &&
        other.showCardRatings == showCardRatings &&
        other.showCardGenres == showCardGenres &&
        other.showCardYear == showCardYear &&
        other.useNewUi == useNewUi &&
        other.sheetPhysics == sheetPhysics &&
        mapEquals(other.cardStyleWideModes, cardStyleWideModes);
  }

  @override
  int get hashCode => Object.hash(
    cardStyle,
    continueWatchingStyle,
    continueReadingStyle,
    episodeViewMode,
    navBarStyle,
    homeHeaderStyle,
    cardStyleWideModes,
    showCardRatings,
    showCardGenres,
    showCardYear,
    useNewUi,
    sheetPhysics,
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

  void setUseNewUi(bool value) {
    state = state.copyWith(useNewUi: value);
    _saveDb();
  }

  void toggleNewUi() => setUseNewUi(!state.useNewUi);

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

  void toggleContinueWatchingWide(String styleName) {
    final current = state.isContinueWatchingWide(styleName);
    setWideCardMode('cw_$styleName', !current);
  }

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

  void updateUiPrefs(UiPrefState Function(UiPrefState) updater) {
    state = updater(state);
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

  void updateHomeHeaderStyle(HomeHeaderStyle style) {
    state = state.copyWith(homeHeaderStyle: style);
    _saveDb();
  }

  void setSheetPhysics(bool value) {
    if (state.sheetPhysics == value) return;
    state = state.copyWith(sheetPhysics: value);
    _saveDb();
  }

  void toggleSheetPhysics() => setSheetPhysics(!state.sheetPhysics);

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
