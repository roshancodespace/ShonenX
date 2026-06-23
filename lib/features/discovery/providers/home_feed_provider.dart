import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/content_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class FeedGroup {
  final String title;
  final List<UnifiedMedia> items;

  const FeedGroup({required this.title, required this.items});
}

class HomeFeedState {
  final List<FeedGroup> groups;

  const HomeFeedState({required this.groups});

  List<UnifiedMedia> get trending =>
      groups.isNotEmpty ? groups.first.items : [];
}

final homeFeedProvider = AsyncNotifierProvider<HomeFeedNotifier, HomeFeedState>(
  () => HomeFeedNotifier(),
  name: 'homeFeedProvider',
);

class HomeFeedNotifier extends AsyncNotifier<HomeFeedState> {
  @override
  Future<HomeFeedState> build() async {
    final prefs = ref.watch(discoveryPrefsProvider);

    if (prefs.mode == MetadataMode.tracker) {
      return _buildTrackerFeed();
    } else {
      return _buildSourceFeed(prefs);
    }
  }

  Future<HomeFeedState> _buildTrackerFeed() async {
    final tracker = ref.watch(metadataSourceProvider);
    final adultMode = ref.watch(contentPrefsProvider).adultContentMode;
    
    final animeResult = await tracker.getTrending(type: MediaType.ANIME, adultMode: adultMode);
    final mangaResult = await tracker.getTrending(type: MediaType.MANGA, adultMode: adultMode);
    
    return HomeFeedState(
      groups: [
        if (animeResult.items.isNotEmpty)
          FeedGroup(title: 'Trending Anime', items: animeResult.items),
        if (mangaResult.items.isNotEmpty)
          FeedGroup(title: 'Trending Manga', items: mangaResult.items),
      ],
    );
  }

  Future<HomeFeedState> _buildSourceFeed(DiscoveryPrefs prefs) async {
    final allAnimeSources = await ref.watch(availableAnimeSourcesProvider.future);
    final allMangaSources = await ref.watch(availableMangaSourcesProvider.future);

    final activeAnimeSources = allAnimeSources
        .where((s) => prefs.activeSources.contains(s.id))
        .toList();
    final activeMangaSources = allMangaSources
        .where((s) => prefs.activeSources.contains(s.id))
        .toList();

    if (activeAnimeSources.isEmpty && activeMangaSources.isEmpty) {
      return const HomeFeedState(groups: []);
    }

    // Fetch trending from each anime source concurrently.
    final animeFutures = activeAnimeSources.map((info) async {
      try {
        final source = ref.read(animeSourceProvider(info));
        final items = await source.getTrending();
        return FeedGroup(title: '${info.name} (Anime)', items: items);
      } catch (_) {
        return FeedGroup(title: info.name, items: const []);
      }
    });

    // Fetch trending from each manga source concurrently.
    final mangaFutures = activeMangaSources.map((info) async {
      try {
        final source = ref.read(mangaSourceProvider(info));
        final items = await source.getTrending();
        return FeedGroup(title: '${info.name} (Manga)', items: items);
      } catch (_) {
        return FeedGroup(title: info.name, items: const []);
      }
    });

    final groups = await Future.wait([...animeFutures, ...mangaFutures]);
    // Remove empty groups.
    final nonEmpty = groups.where((g) => g.items.isNotEmpty).toList();

    return HomeFeedState(groups: nonEmpty);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}
