import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/providers/storage_provider.dart';
import 'package:shonenx/core/models/component_layout.dart';

enum MediaCardStyle {
  classic(ComponentLayout(width: 120, height: 200)),
  minimal(ComponentLayout(width: 120, height: 180)),
  expressive(ComponentLayout(width: 140, height: 230)),
  material(ComponentLayout(width: 135, height: 210)),
  liquidGlass(ComponentLayout(width: 140, height: 210));

  final ComponentLayout layout;
  const MediaCardStyle(this.layout);

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
  classic(ComponentLayout(width: 160, height: 140)),
  wideBanner(ComponentLayout(width: 300, height: 120));

  final ComponentLayout layout;
  const ContinueWatchingStyle(this.layout);

  String get displayName {
    switch (this) {
      case ContinueWatchingStyle.classic:
        return 'Classic';
      case ContinueWatchingStyle.wideBanner:
        return 'Wide Banner';
    }
  }
}

class UiPrefState {
  final MediaCardStyle cardStyle;
  final ContinueWatchingStyle continueWatchingStyle;

  const UiPrefState({
    this.cardStyle = MediaCardStyle.classic,
    this.continueWatchingStyle = ContinueWatchingStyle.classic,
  });

  UiPrefState copyWith({
    MediaCardStyle? cardStyle,
    ContinueWatchingStyle? continueWatchingStyle,
  }) {
    return UiPrefState(
      cardStyle: cardStyle ?? this.cardStyle,
      continueWatchingStyle:
          continueWatchingStyle ?? this.continueWatchingStyle,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardStyle': cardStyle.name,
    'continueWatchingStyle': continueWatchingStyle.name,
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
    );
  }

  @override
  String toString() =>
      'UiPrefState(cardStyle: $cardStyle, continueWatchingStyle: $continueWatchingStyle)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UiPrefState &&
        other.cardStyle == cardStyle &&
        other.continueWatchingStyle == continueWatchingStyle;
  }

  @override
  int get hashCode => Object.hash(cardStyle, continueWatchingStyle);
}

class UiPreferencesNotifier extends Notifier<UiPrefState> {
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

final uiPrefsProvider = NotifierProvider<UiPreferencesNotifier, UiPrefState>(
  UiPreferencesNotifier.new,
);
