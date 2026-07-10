import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class UserHomeLayoutNotifier extends Notifier<List<HomeSection>> {
  static const _dataKey = 'home_layout_data';
  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  List<HomeSection> build() {
    final json = _storage.getStringList(_dataKey);

    if (json != null && json.isNotEmpty) {
      return json.map((e) => HomeSection.fromJson(e)).toList();
    }

    return const [
      HomeSection(
        id: '1',
        title: 'Trending Anime',
        type: HomeSectionType.trending,
        targetMediaType: MediaType.ANIME,
      ),
      HomeSection(
        id: '2',
        title: 'Trending Manga',
        type: HomeSectionType.trending,
        targetMediaType: MediaType.MANGA,
      ),
      HomeSection(
        id: '3',
        title: 'Continue Watching',
        type: HomeSectionType.continueMedia,
        targetMediaType: MediaType.ANIME,
      ),
      HomeSection(
        id: '4',
        title: 'Continue Reading',
        type: HomeSectionType.continueMedia,
        targetMediaType: MediaType.MANGA,
      ),
    ];
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    state = list;
    _saveDb();
  }

  void addSection(HomeSection section) {
    state = [...state, section];
    _saveDb();
  }

  void removeSection(String id) {
    state = state.where((e) => e.id != id).toList();
    _saveDb();
  }

  void updateSection(HomeSection updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
    _saveDb();
  }

  void reset() {
    _storage.remove(_dataKey);
    state = build();
  }

  void setSections(List<HomeSection> sections) {
    state = sections;
    _saveDb();
  }

  void setupHomeLayoutForContentPreference({
    required bool includeAnime,
    required bool includeManga,
  }) {
    if (includeAnime && !includeManga) {
      state = const [
        HomeSection(
          id: '1',
          title: 'Trending Anime',
          type: HomeSectionType.trending,
          targetMediaType: MediaType.ANIME,
        ),
        HomeSection(
          id: '3',
          title: 'Continue Watching',
          type: HomeSectionType.continueMedia,
          targetMediaType: MediaType.ANIME,
        ),
      ];
    } else if (!includeAnime && includeManga) {
      state = const [
        HomeSection(
          id: '2',
          title: 'Trending Manga',
          type: HomeSectionType.trending,
          targetMediaType: MediaType.MANGA,
        ),
        HomeSection(
          id: '4',
          title: 'Continue Reading',
          type: HomeSectionType.continueMedia,
          targetMediaType: MediaType.MANGA,
        ),
      ];
    } else {
      state = const [
        HomeSection(
          id: '1',
          title: 'Trending Anime',
          type: HomeSectionType.trending,
          targetMediaType: MediaType.ANIME,
        ),
        HomeSection(
          id: '2',
          title: 'Trending Manga',
          type: HomeSectionType.trending,
          targetMediaType: MediaType.MANGA,
        ),
        HomeSection(
          id: '3',
          title: 'Continue Watching',
          type: HomeSectionType.continueMedia,
          targetMediaType: MediaType.ANIME,
        ),
        HomeSection(
          id: '4',
          title: 'Continue Reading',
          type: HomeSectionType.continueMedia,
          targetMediaType: MediaType.MANGA,
        ),
      ];
    }
    _saveDb();
  }

  void _saveDb() {
    _storage.setStringList(_dataKey, state.map((e) => e.toJson()).toList());
  }
}

final userHomeLayoutProvider =
    NotifierProvider<UserHomeLayoutNotifier, List<HomeSection>>(
      UserHomeLayoutNotifier.new,
      name: 'userHomeLayoutProvider',
    );
