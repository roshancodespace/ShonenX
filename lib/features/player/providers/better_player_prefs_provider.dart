import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class BetterPlayerPrefsState {
  final bool enableCache;
  final int maxCacheSizeMb;
  final bool useAsmsSubtitles;
  final bool useAsmsAudioTracks;

  const BetterPlayerPrefsState({
    this.enableCache = true,
    this.maxCacheSizeMb = 100,
    this.useAsmsSubtitles = true,
    this.useAsmsAudioTracks = true,
  });

  BetterPlayerPrefsState copyWith({
    bool? enableCache,
    int? maxCacheSizeMb,
    bool? useAsmsSubtitles,
    bool? useAsmsAudioTracks,
  }) {
    return BetterPlayerPrefsState(
      enableCache: enableCache ?? this.enableCache,
      maxCacheSizeMb: maxCacheSizeMb ?? this.maxCacheSizeMb,
      useAsmsSubtitles: useAsmsSubtitles ?? this.useAsmsSubtitles,
      useAsmsAudioTracks: useAsmsAudioTracks ?? this.useAsmsAudioTracks,
    );
  }

  factory BetterPlayerPrefsState.fromMap(Map<String, dynamic> map) {
    return BetterPlayerPrefsState(
      enableCache: map['enableCache'] ?? true,
      maxCacheSizeMb: map['maxCacheSizeMb'] ?? 100,
      useAsmsSubtitles: map['useAsmsSubtitles'] ?? true,
      useAsmsAudioTracks: map['useAsmsAudioTracks'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableCache': enableCache,
      'maxCacheSizeMb': maxCacheSizeMb,
      'useAsmsSubtitles': useAsmsSubtitles,
      'useAsmsAudioTracks': useAsmsAudioTracks,
    };
  }
}

class BetterPlayerPrefsNotifier extends Notifier<BetterPlayerPrefsState> {
  static const _key = 'better_player_prefs';

  @override
  BetterPlayerPrefsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json != null) {
      return BetterPlayerPrefsState.fromMap(jsonDecode(json));
    }
    return const BetterPlayerPrefsState();
  }

  void updatePrefs(BetterPlayerPrefsState newState) {
    state = newState;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_key, jsonEncode(state.toMap()));
  }
}

final betterPlayerPrefsProvider =
    NotifierProvider<BetterPlayerPrefsNotifier, BetterPlayerPrefsState>(
      BetterPlayerPrefsNotifier.new,
    );
