import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/models/component_layout.dart';
import 'package:shonenx/core/providers/storage_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';

class GlobalScale {
  static double uiScaleFactor = 1.0;
  static double uiRoundness = 12.0;
}

enum MediaCardStyle {
  classic(ComponentLayout(width: 125, height: 215)),
  minimal(ComponentLayout(width: 120, height: 180)),
  expressive(ComponentLayout(width: 140, height: 230)),
  material(ComponentLayout(width: 135, height: 210)),
  liquidGlass(ComponentLayout(width: 140, height: 210));

  final ComponentLayout _baseLayout;
  const MediaCardStyle(this._baseLayout);

  ComponentLayout get layout {
    return ComponentLayout(
      width: _baseLayout.width * GlobalScale.uiScaleFactor,
      height: _baseLayout.height * GlobalScale.uiScaleFactor,
    );
  }

  ComponentLayout getScaledLayout(double scale) {
    return ComponentLayout(
      width: layout.width * scale,
      height: layout.height * scale,
    );
  }

  String get displayName {
    switch (this) {
      case MediaCardStyle.classic:
        return 'Classic';
      case MediaCardStyle.minimal:
        return 'Minimal';
      case MediaCardStyle.expressive:
        return 'Expressive';
      case MediaCardStyle.material:
        return 'Material';
      case MediaCardStyle.liquidGlass:
        return 'Liquid Glass';
    }
  }
}

enum ContinueWatchingStyle {
  classic(ComponentLayout(width: 180, height: 180)),
  wideBanner(ComponentLayout(width: 390, height: 125));

  final ComponentLayout _baseLayout;
  const ContinueWatchingStyle(this._baseLayout);

  ComponentLayout get layout {
    return ComponentLayout(
      width: _baseLayout.width * GlobalScale.uiScaleFactor,
      height: _baseLayout.height * GlobalScale.uiScaleFactor,
    );
  }

  ComponentLayout getScaledLayout(double scale) {
    return ComponentLayout(
      width: layout.width * scale,
      height: layout.height * scale,
    );
  }

  String get displayName {
    switch (this) {
      case ContinueWatchingStyle.classic:
        return 'Classic';
      case ContinueWatchingStyle.wideBanner:
        return 'Wide Banner';
    }
  }
}

enum ContinueReadingStyle {
  classic(ComponentLayout(width: 140, height: 210)),
  wideBanner(ComponentLayout(width: 390, height: 125));

  final ComponentLayout _baseLayout;
  const ContinueReadingStyle(this._baseLayout);

  ComponentLayout get layout {
    return ComponentLayout(
      width: _baseLayout.width * GlobalScale.uiScaleFactor,
      height: _baseLayout.height * GlobalScale.uiScaleFactor,
    );
  }

  ComponentLayout getScaledLayout(double scale) {
    return ComponentLayout(
      width: layout.width * scale,
      height: layout.height * scale,
    );
  }

  String get displayName {
    switch (this) {
      case ContinueReadingStyle.classic:
        return 'Classic';
      case ContinueReadingStyle.wideBanner:
        return 'Wide Banner';
    }
  }
}

class UiPrefState {
  final MediaCardStyle cardStyle;
  final ContinueWatchingStyle continueWatchingStyle;
  final ContinueReadingStyle continueReadingStyle;
  final EpisodeViewMode episodeViewMode;

  const UiPrefState({
    this.cardStyle = MediaCardStyle.classic,
    this.continueWatchingStyle = ContinueWatchingStyle.classic,
    this.continueReadingStyle = ContinueReadingStyle.classic,
    this.episodeViewMode = EpisodeViewMode.classic,
  });

  UiPrefState copyWith({
    MediaCardStyle? cardStyle,
    ContinueWatchingStyle? continueWatchingStyle,
    ContinueReadingStyle? continueReadingStyle,
    EpisodeViewMode? episodeViewMode,
  }) {
    return UiPrefState(
      cardStyle: cardStyle ?? this.cardStyle,
      continueWatchingStyle:
          continueWatchingStyle ?? this.continueWatchingStyle,
      continueReadingStyle: continueReadingStyle ?? this.continueReadingStyle,
      episodeViewMode: episodeViewMode ?? this.episodeViewMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardStyle': cardStyle.name,
    'continueWatchingStyle': continueWatchingStyle.name,
    'continueReadingStyle': continueReadingStyle.name,
    'episodeViewMode': episodeViewMode.name,
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
    );
  }

  @override
  String toString() =>
      'UiPrefState(cardStyle: $cardStyle, continueWatchingStyle: $continueWatchingStyle, continueReadingStyle: $continueReadingStyle, episodeViewMode: $episodeViewMode)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UiPrefState &&
        other.cardStyle == cardStyle &&
        other.continueWatchingStyle == continueWatchingStyle &&
        other.continueReadingStyle == continueReadingStyle &&
        other.episodeViewMode == episodeViewMode;
  }

  @override
  int get hashCode => Object.hash(
    cardStyle,
    continueWatchingStyle,
    continueReadingStyle,
    episodeViewMode,
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
