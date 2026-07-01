import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/domain/gesture_prefs.dart';

enum PlayerType {
  mediakit,
  betterplayer,
  mdk;

  factory PlayerType.fromString(String? value) {
    return PlayerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlayerType.mediakit,
    );
  }
}

class PlayerPrefsState {
  final PlayerType playerType;
  final GesturePrefs gesturePrefs;
  final bool showShortcutsSheetOnStart;

  const PlayerPrefsState({
    this.playerType = PlayerType.mediakit,
    this.gesturePrefs = const GesturePrefs(),
    this.showShortcutsSheetOnStart = true,
  });

  PlayerPrefsState copyWith({
    AniSkipPrefs? aniSkipPrefs,
    PlayerType? playerType,
    GesturePrefs? gesturePrefs,
    bool? showShortcutsSheetOnStart,
  }) {
    return PlayerPrefsState(
      playerType: playerType ?? this.playerType,
      gesturePrefs: gesturePrefs ?? this.gesturePrefs,
      showShortcutsSheetOnStart:
          showShortcutsSheetOnStart ?? this.showShortcutsSheetOnStart,
    );
  }

  factory PlayerPrefsState.fromMap(Map<String, dynamic> map) {
    return PlayerPrefsState(
      playerType: PlayerType.fromString(map['playerType']),
      gesturePrefs: map['gesturePrefs'] != null
          ? GesturePrefs.fromMap(map['gesturePrefs'])
          : const GesturePrefs(),
      showShortcutsSheetOnStart: map['showShortcutsSheetOnStart'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerType': playerType.name,
      'gesturePrefs': gesturePrefs.toMap(),
      'showShortcutsSheetOnStart': showShortcutsSheetOnStart,
    };
  }

  factory PlayerPrefsState.fromJson(Map<String, dynamic> json) {
    return PlayerPrefsState.fromMap(json);
  }

  Map<String, dynamic> toJson() => toMap();
}

class PlayerPrefsNotifier extends Notifier<PlayerPrefsState> {
  static const _key = 'player_prefs';
  Timer? _debounce;

  @override
  PlayerPrefsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json != null) {
      return PlayerPrefsState.fromJson(jsonDecode(json));
    }
    return PlayerPrefsState(
      playerType: Platform.isAndroid
          ? PlayerType.mediakit
          : PlayerType.mediakit,
    );
  }

  void changePlayer(PlayerType playerType) {
    state = state.copyWith(playerType: playerType);
    _saveDb();
  }

  void updateGesturePrefs(GesturePrefs gesturePrefs) {
    state = state.copyWith(gesturePrefs: gesturePrefs);
    _saveDb();
  }

  void toggleShowShortcutsSheetOnStart(bool value) {
    state = state.copyWith(showShortcutsSheetOnStart: value);
    _saveDb();
  }

  void _saveDb() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final prefs = ref.read(sharedPreferencesProvider);
      final newValue = jsonEncode(state.toJson());

      if (prefs.getString(_key) != newValue) {
        prefs.setString(_key, newValue);
      }
    });
  }
}

final playerPrefsProvider =
    NotifierProvider<PlayerPrefsNotifier, PlayerPrefsState>(
      PlayerPrefsNotifier.new,
    );
