import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/domain/gesture_prefs.dart';
import 'package:shonenx/shared/models/video_server.dart';

enum PlayerType {
  mediakit,
  videoPlayer;

  factory PlayerType.fromString(String? value) {
    if (value == 'betterplayer' || value == 'mdk' || value == 'videoPlayer') {
      return PlayerType.videoPlayer;
    }
    return PlayerType.mediakit;
  }
}

class PlayerPrefsState {
  final PlayerType playerType;
  final GesturePrefs gesturePrefs;
  final bool showShortcutsSheetOnStart;
  final String defaultQuality;
  final String defaultAudioLang;
  final String defaultSubtitleLang;
  final ServerType defaultServerType;

  const PlayerPrefsState({
    this.playerType = PlayerType.mediakit,
    this.gesturePrefs = const GesturePrefs(),
    this.showShortcutsSheetOnStart = true,
    this.defaultQuality = '1080p',
    this.defaultAudioLang = 'eng',
    this.defaultSubtitleLang = 'eng',
    this.defaultServerType = ServerType.sub,
  });

  PlayerPrefsState copyWith({
    AniSkipPrefs? aniSkipPrefs,
    PlayerType? playerType,
    GesturePrefs? gesturePrefs,
    bool? showShortcutsSheetOnStart,
    String? defaultQuality,
    String? defaultAudioLang,
    String? defaultSubtitleLang,
    ServerType? defaultServerType,
  }) {
    return PlayerPrefsState(
      playerType: playerType ?? this.playerType,
      gesturePrefs: gesturePrefs ?? this.gesturePrefs,
      showShortcutsSheetOnStart:
          showShortcutsSheetOnStart ?? this.showShortcutsSheetOnStart,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      defaultAudioLang: defaultAudioLang ?? this.defaultAudioLang,
      defaultSubtitleLang: defaultSubtitleLang ?? this.defaultSubtitleLang,
      defaultServerType: defaultServerType ?? this.defaultServerType,
    );
  }

  factory PlayerPrefsState.fromMap(Map<String, dynamic> map) {
    return PlayerPrefsState(
      playerType: PlayerType.fromString(map['playerType']),
      gesturePrefs: map['gesturePrefs'] != null
          ? GesturePrefs.fromMap(map['gesturePrefs'])
          : const GesturePrefs(),
      showShortcutsSheetOnStart: map['showShortcutsSheetOnStart'] ?? true,
      defaultQuality: map['defaultQuality'] ?? '1080p',
      defaultAudioLang: map['defaultAudioLang'] ?? 'eng',
      defaultSubtitleLang: map['defaultSubtitleLang'] ?? 'eng',
      defaultServerType: map['defaultServerType'] != null
          ? ServerType.values.firstWhere(
              (e) => e.name == map['defaultServerType'],
              orElse: () => ServerType.sub,
            )
          : ServerType.sub,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerType': playerType.name,
      'gesturePrefs': gesturePrefs.toMap(),
      'showShortcutsSheetOnStart': showShortcutsSheetOnStart,
      'defaultQuality': defaultQuality,
      'defaultAudioLang': defaultAudioLang,
      'defaultSubtitleLang': defaultSubtitleLang,
      'defaultServerType': defaultServerType.name,
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

  void setDefaultQuality(String quality) {
    state = state.copyWith(defaultQuality: quality);
    _saveDb();
  }

  void setDefaultAudioLang(String lang) {
    state = state.copyWith(defaultAudioLang: lang);
    _saveDb();
  }

  void setDefaultSubtitleLang(String lang) {
    state = state.copyWith(defaultSubtitleLang: lang);
    _saveDb();
  }

  void setDefaultServerType(ServerType type) {
    state = state.copyWith(defaultServerType: type);
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
