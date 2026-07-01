import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class MetadataTagsState {
  final List<String> genres;
  final List<String> tags;

  const MetadataTagsState({this.genres = const [], this.tags = const []});
}

final metadataTagsProvider = FutureProvider.autoDispose<MetadataTagsState>((
  ref,
) async {
  final source = ref.watch(metadataSourceProvider);

  final genres = await source.fetchGenres();
  final tags = await source.fetchTags();

  return MetadataTagsState(genres: genres, tags: tags);
});

typedef DiscoveryFilterArgs = ({MediaType type, String? sourceId});

final discoveryFiltersProvider = FutureProvider.autoDispose
    .family<MetadataTagsState, DiscoveryFilterArgs>((ref, args) async {
      final prefs = ref.watch(discoveryPrefsProvider);

      if (args.sourceId != null || prefs.mode == MetadataMode.source) {
        final allSources = await ref.watch(
          args.type == MediaType.ANIME
              ? availableAnimeSourcesProvider.future
              : availableMangaSourcesProvider.future,
        );

        final targetSourceIds = args.sourceId != null
            ? [args.sourceId!]
            : prefs.activeSources;

        final activeSources = allSources
            .where((s) => targetSourceIds.contains(s.id))
            .toList();

        final Set<String> allGenres = {};
        final Set<String> allTags = {};

        for (final info in activeSources) {
          try {
            final source = args.type == MediaType.ANIME
                ? ref.read(animeSourceProvider(info))
                : ref.read(mangaSourceProvider(info));

            final genres = await source.getFilterGenres();
            final tags = await source.getFilterTags();
            allGenres.addAll(genres);
            allTags.addAll(tags);
          } catch (_) {}
        }

        return MetadataTagsState(
          genres: allGenres.toList()..sort(),
          tags: allTags.toList()..sort(),
        );
      } else {
        final tracker = ref.watch(metadataSourceProvider);
        final genres = await tracker.fetchGenres();
        final tags = await tracker.fetchTags();
        return MetadataTagsState(genres: genres, tags: tags);
      }
    });
