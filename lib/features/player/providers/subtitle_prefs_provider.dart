import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/player/domain/subtitle_prefs.dart';

class SubtitlePrefsNotifier extends Notifier<SubtitlePrefs> {
  static const _key = 'subtitle_prefs';
  Timer? _debounce;

  @override
  SubtitlePrefs build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        return SubtitlePrefs.fromMap(jsonDecode(jsonStr));
      } catch (e) {
        // Fallback to default
      }
    }
    return const SubtitlePrefs();
  }

  void updatePrefs(SubtitlePrefs newPrefs) {
    state = newPrefs;
    _saveDb();
  }

  void _saveDb() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final prefs = ref.read(sharedPreferencesProvider);
      final newValue = jsonEncode(state.toMap());
      if (prefs.getString(_key) != newValue) {
        prefs.setString(_key, newValue);
      }
    });
  }
}

final subtitlePrefsProvider =
    NotifierProvider<SubtitlePrefsNotifier, SubtitlePrefs>(
  SubtitlePrefsNotifier.new,
);
