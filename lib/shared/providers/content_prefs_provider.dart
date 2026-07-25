import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

import 'package:shonenx/shared/models/unified_media.dart';

enum AdultContentMode {
  safe('Safe'),
  mixed('Mixed'),
  adultOnly('Adult Only');

  final String label;
  const AdultContentMode(this.label);
}

class ContentPrefs {
  final AdultContentMode adultContentMode;
  final TitlePreference titlePreference;

  const ContentPrefs({
    this.adultContentMode = AdultContentMode.safe,
    this.titlePreference = TitlePreference.english,
  });

  Map<String, dynamic> toJson() {
    return {
      'adultContentMode': adultContentMode.index,
      'titlePreference': titlePreference.name,
    };
  }

  factory ContentPrefs.fromJson(Map<String, dynamic> json) {
    return ContentPrefs(
      adultContentMode:
          AdultContentMode.values.elementAtOrNull(
            json['adultContentMode'] as int? ?? 0,
          ) ??
          AdultContentMode.safe,
      titlePreference: TitlePreference.values.firstWhere(
        (e) => e.name == json['titlePreference'],
        orElse: () => TitlePreference.english,
      ),
    );
  }

  ContentPrefs copyWith({
    AdultContentMode? adultContentMode,
    TitlePreference? titlePreference,
  }) {
    return ContentPrefs(
      adultContentMode: adultContentMode ?? this.adultContentMode,
      titlePreference: titlePreference ?? this.titlePreference,
    );
  }
}

class ContentPrefsNotifier extends Notifier<ContentPrefs> {
  static const _keyPrefs = 'content_prefs';

  @override
  ContentPrefs build() {
    final storage = ref.watch(sharedPreferencesProvider);
    final jsonStr = storage.getString(_keyPrefs);
    ContentPrefs prefs = const ContentPrefs();
    
    if (jsonStr != null) {
      try {
        prefs = ContentPrefs.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    
    // Sync static title preference on MediaTitle
    MediaTitle.preference = prefs.titlePreference;
    
    return prefs;
  }

  Future<void> _savePrefs(ContentPrefs prefs) async {
    state = prefs;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_keyPrefs, jsonEncode(prefs.toJson()));
  }

  Future<void> setAdultContentMode(AdultContentMode mode) async {
    await _savePrefs(state.copyWith(adultContentMode: mode));
  }

  Future<void> setTitlePreference(TitlePreference preference) async {
    await _savePrefs(state.copyWith(titlePreference: preference));
    MediaTitle.preference = preference;
  }
}

final contentPrefsProvider =
    NotifierProvider<ContentPrefsNotifier, ContentPrefs>(
      () => ContentPrefsNotifier(),
    );
