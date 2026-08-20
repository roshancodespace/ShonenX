import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_filter_options.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class MetadataTagsState {
  final TrackerFilterOptions options;

  const MetadataTagsState({this.options = const TrackerFilterOptions()});

  List<String> get genres => options.genres;
  List<String> get tags => options.tags;
}

final metadataTagsProvider = FutureProvider.autoDispose<MetadataTagsState>((
  ref,
) async {
  final source = ref.watch(metadataSourceProvider);
  final options = await source.fetchFilterOptions();
  return MetadataTagsState(options: options);
});

typedef DiscoveryFilterArgs = ({MediaType type, String? sourceId});

final discoveryFiltersProvider = FutureProvider.autoDispose
    .family<MetadataTagsState, DiscoveryFilterArgs>((ref, args) async {
      final prefs = ref.watch(discoveryPrefsProvider);

      if (args.sourceId != null || prefs.mode == MetadataMode.source) {
        final allSources = await ref.watch(
          args.type.availableSourcesProvider.future,
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
            final source = args.type.usesAnimeSources
                ? ref.read(animeSourceProvider(info))
                : ref.read(mangaSourceProvider(info));

            final genres = await source.getFilterGenres();
            final tags = await source.getFilterTags();
            allGenres.addAll(genres);
            allTags.addAll(tags);
          } catch (_) {}
        }

        return MetadataTagsState(
          options: TrackerFilterOptions(
            genres: allGenres.toList()..sort(),
            tags: allTags.toList()..sort(),
          ),
        );
      } else {
        final tracker = ref.watch(metadataSourceProvider);
        final options = await tracker.fetchFilterOptions(args.type);
        return MetadataTagsState(options: options);
      }
    });
