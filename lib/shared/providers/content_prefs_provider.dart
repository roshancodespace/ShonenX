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

enum EpisodeMetadataProviderType {
  auto('Auto (Tenrai + Kitsu)'),
  tenrai('Tenrai'),
  kitsu('Kitsu'),
  disabled('Disabled'),
  @Deprecated('Jikan is disabled; use tenrai instead')
  jikan('Jikan (Disabled)');

  final String displayName;
  const EpisodeMetadataProviderType(this.displayName);
}

class ContentPrefs {
  final AdultContentMode adultContentMode;
  final TitlePreference titlePreference;
  final EpisodeMetadataProviderType episodeMetadataProvider;

  const ContentPrefs({
    this.adultContentMode = AdultContentMode.safe,
    this.titlePreference = TitlePreference.english,
    this.episodeMetadataProvider = EpisodeMetadataProviderType.auto,
  });

  Map<String, dynamic> toJson() {
    return {
      'adultContentMode': adultContentMode.index,
      'titlePreference': titlePreference.name,
      'episodeMetadataProvider': episodeMetadataProvider.name,
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
      episodeMetadataProvider: EpisodeMetadataProviderType.values.firstWhere(
        (e) => e.name == json['episodeMetadataProvider'],
        orElse: () => EpisodeMetadataProviderType.auto,
      ),
    );
  }

  ContentPrefs copyWith({
    AdultContentMode? adultContentMode,
    TitlePreference? titlePreference,
    EpisodeMetadataProviderType? episodeMetadataProvider,
  }) {
    return ContentPrefs(
      adultContentMode: adultContentMode ?? this.adultContentMode,
      titlePreference: titlePreference ?? this.titlePreference,
      episodeMetadataProvider:
          episodeMetadataProvider ?? this.episodeMetadataProvider,
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

  Future<void> setEpisodeMetadataProvider(
    EpisodeMetadataProviderType providerType,
  ) async {
    await _savePrefs(state.copyWith(episodeMetadataProvider: providerType));
  }
}

final contentPrefsProvider =
    NotifierProvider<ContentPrefsNotifier, ContentPrefs>(
      () => ContentPrefsNotifier(),
    );
