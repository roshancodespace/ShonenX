import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final result = await tracker.getTrending();
    return HomeFeedState(
      groups: [FeedGroup(title: 'Trending', items: result.items)],
    );
  }

  Future<HomeFeedState> _buildSourceFeed(DiscoveryPrefs prefs) async {
    final allSources = await ref.watch(availableAnimeSourcesProvider.future);

    final activeSources = allSources
        .where((s) => prefs.activeSources.contains(s.id))
        .toList();

    if (activeSources.isEmpty) {
      return const HomeFeedState(groups: []);
    }

    // Fetch trending from each source concurrently.
    final futures = activeSources.map((info) async {
      try {
        final source = ref.read(animeSourceProvider(info));
        final items = await source.getTrending();
        return FeedGroup(title: info.name, items: items);
      } catch (_) {
        return FeedGroup(title: info.name, items: const []);
      }
    });

    final groups = await Future.wait(futures);
    // Remove empty groups.
    final nonEmpty = groups.where((g) => g.items.isNotEmpty).toList();

    return HomeFeedState(groups: nonEmpty);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}
