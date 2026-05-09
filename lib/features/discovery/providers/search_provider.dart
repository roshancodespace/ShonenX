import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

final searchProvider =
    AsyncNotifierProvider<SearchNotifier, PaginatedResult<UnifiedMedia>?>(() {
      return SearchNotifier();
    }, name: 'searchProvider');

class SearchNotifier extends AsyncNotifier<PaginatedResult<UnifiedMedia>?> {
  @override
  Future<PaginatedResult<UnifiedMedia>?> build() async {
    return null;
  }

  Future<void> search(String query, {MediaType type = MediaType.ANIME}) async {
    if (query.isEmpty) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();

    try {
      final prefs = ref.read(discoveryPrefsProvider);

      if (prefs.mode == MetadataMode.tracker) {
        final engine = ref.read(metadataSourceProvider);
        final result = await engine.search(query, type: type);
        state = AsyncData(result);
      } else {
        final allSources = await ref.read(availableAnimeSourcesProvider.future);
        final activeSources = allSources
            .where((s) => prefs.activeSources.contains(s.id))
            .toList();

        if (activeSources.isEmpty) {
          state = const AsyncData(
            PaginatedResult(items: [], hasNextPage: false),
          );
          return;
        }

        // Search all active sources concurrently and merge results.
        final futures = activeSources.map((info) async {
          try {
            final source = ref.read(animeSourceProvider(info));
            return await source.search(query, MediaType.ANIME);
          } catch (_) {
            return <UnifiedMedia>[];
          }
        });

        final results = await Future.wait(futures);
        final merged = results.expand((list) => list).toList();

        state = AsyncData(PaginatedResult(items: merged, hasNextPage: false));
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
