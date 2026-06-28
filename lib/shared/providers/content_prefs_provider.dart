import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

enum AdultContentMode {
  safe('Safe'),
  mixed('Mixed'),
  adultOnly('Adult Only');

  final String label;
  const AdultContentMode(this.label);
}

class ContentPrefs {
  final AdultContentMode adultContentMode;

  const ContentPrefs({this.adultContentMode = AdultContentMode.safe});

  Map<String, dynamic> toJson() {
    return {'adultContentMode': adultContentMode.index};
  }

  factory ContentPrefs.fromJson(Map<String, dynamic> json) {
    return ContentPrefs(
      adultContentMode:
          AdultContentMode.values.elementAtOrNull(
            json['adultContentMode'] as int? ?? 0,
          ) ??
          AdultContentMode.safe,
    );
  }

  ContentPrefs copyWith({AdultContentMode? adultContentMode}) {
    return ContentPrefs(
      adultContentMode: adultContentMode ?? this.adultContentMode,
    );
  }
}

class ContentPrefsNotifier extends Notifier<ContentPrefs> {
  static const _keyPrefs = 'content_prefs';

  @override
  ContentPrefs build() {
    final storage = ref.watch(sharedPreferencesProvider);
    final jsonStr = storage.getString(_keyPrefs);
    if (jsonStr != null) {
      try {
        return ContentPrefs.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    return const ContentPrefs();
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
}

final contentPrefsProvider =
    NotifierProvider<ContentPrefsNotifier, ContentPrefs>(
      () => ContentPrefsNotifier(),
    );
