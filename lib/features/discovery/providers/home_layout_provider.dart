import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';

class UserHomeLayoutNotifier extends Notifier<List<HomeSection>> {
  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  String get _dataKey {
    final prefs = ref.read(discoveryPrefsProvider);
    if (prefs.mode == MetadataMode.source) {
      return 'home_layout_source';
    } else {
      final tracker = ref.read(metadataSourceProvider);
      return 'home_layout_tracker_${tracker.type.name}';
    }
  }

  @override
  List<HomeSection> build() {
    final prefs = ref.watch(discoveryPrefsProvider);
    RemoteTracker? tracker;
    if (prefs.mode == MetadataMode.tracker) {
      tracker = ref.watch(metadataSourceProvider);
    }

    final key = _dataKey;
    final json = _storage.getStringList(key);

    if (json != null && json.isNotEmpty) {
      return json.map((e) => HomeSection.fromJson(e)).toList();
    }

    if (prefs.mode == MetadataMode.source || tracker == null) {
      return const [
        HomeSection(
          id: '1',
          title: 'Trending Anime',
          type: HomeSectionType.discovery,
          targetMediaType: MediaType.ANIME,
          trackerCategory: TrackerCategory.trending,
        ),
        HomeSection(
          id: '2',
          title: 'Trending Manga',
          type: HomeSectionType.discovery,
          targetMediaType: MediaType.MANGA,
          trackerCategory: TrackerCategory.trending,
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
    } else {
      int idCounter = 1;
      final sections = <HomeSection>[];

      for (final media in tracker.supportedMediaTypes) {
        if (tracker.supportedCategories.contains(TrackerCategory.trending)) {
          sections.add(HomeSection(
            id: (idCounter++).toString(),
            title: '${TrackerCategory.trending.label} ${media.displayName}',
            type: HomeSectionType.discovery,
            targetMediaType: media,
            trackerCategory: TrackerCategory.trending,
          ));
        }
      }

      for (final media in tracker.supportedMediaTypes) {
        sections.add(HomeSection(
          id: (idCounter++).toString(),
          title: (media == MediaType.MANGA || media == MediaType.NOVEL)
              ? 'Continue Reading'
              : 'Continue Watching',
          type: HomeSectionType.continueMedia,
          targetMediaType: media,
        ));
      }

      return sections;
    }
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
    ref.invalidateSelf();
  }

  void setSections(List<HomeSection> sections) {
    state = sections;
    _saveDb();
  }

  void setupHomeLayoutForContentPreference({
    required bool includeAnime,
    required bool includeManga,
  }) {
    // Generate default layout based on current tracker, then filter by user preferences
    _storage.remove(_dataKey);
    final defaults = build();
    
    state = defaults.where((s) {
      if (!includeAnime && s.targetMediaType == MediaType.ANIME) return false;
      if (!includeManga && s.targetMediaType == MediaType.MANGA) return false;
      return true;
    }).toList();
    
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
