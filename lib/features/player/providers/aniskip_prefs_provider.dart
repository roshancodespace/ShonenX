import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';

final aniskipPrefsProvider =
    NotifierProvider<AniskipPrefsNotifier, AniSkipPrefs>(
      AniskipPrefsNotifier.new,
    );

class AniskipPrefsNotifier extends Notifier<AniSkipPrefs> {
  static const _key = 'aniskip_prefs';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AniSkipPrefs build() {
    final json = _prefs.getString(_key);
    if (json != null) {
      return AniSkipPrefs.fromJson(jsonDecode(json));
    }
    return AniSkipPrefs();
  }

  void toggle(SkipType type) {
    final currentMode = state.mode(type);
    final newMode = currentMode == SkipMode.auto
        ? SkipMode.manual
        : SkipMode.auto;
    state = state.updateSegment(type, newMode);
    _saveDb();
  }

  void setMode(SkipType type, SkipMode mode) {
    state = state.updateSegment(type, mode);
    _saveDb();
  }

  void _saveDb() {
    _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
