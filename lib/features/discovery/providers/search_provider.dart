import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

class SearchArgs {
  final String query;
  final MediaType type;
  final List<String> genres;
  final List<String> tags;
  final String? source;

  const SearchArgs({
    required this.query,
    required this.type,
    this.genres = const [],
    this.tags = const [],
    this.source,
  });

  @override
  int get hashCode => Object.hash(
    query,
    type,
    source,
    Object.hashAll(genres),
    Object.hashAll(tags),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchArgs) return false;

    if (query != other.query || type != other.type || source != other.source)
      return false;

    if (genres.length != other.genres.length) return false;
    for (int i = 0; i < genres.length; i++) {
      if (genres[i] != other.genres[i]) return false;
    }

    if (tags.length != other.tags.length) return false;
    for (int i = 0; i < tags.length; i++) {
      if (tags[i] != other.tags[i]) return false;
    }

    return true;
  }
}

final searchProvider = AsyncNotifierProvider.autoDispose
    .family<SearchNotifier, PaginatedResult<UnifiedMedia>?, SearchArgs>(
      SearchNotifier.new,
      name: 'searchProvider',
    );

class SearchNotifier extends AsyncNotifier<PaginatedResult<UnifiedMedia>?> {
  int _currentPage = 1;
  bool _isFetchingNextPage = false;
  SearchArgs arg;

  SearchNotifier(this.arg);

  @override
  Future<PaginatedResult<UnifiedMedia>?> build() async {
    _currentPage = 1;
    _isFetchingNextPage = false;
    if (arg.query.isEmpty &&
        arg.genres.isEmpty &&
        arg.tags.isEmpty &&
        arg.source == null)
      return null;
    return _fetchPage(1);
  }

  Future<PaginatedResult<UnifiedMedia>> _fetchPage(int page) async {
    final prefs = ref.read(discoveryPrefsProvider);

    if (prefs.mode == MetadataMode.tracker) {
      final engine = ref.read(metadataSourceProvider);
      final adultMode = ref.read(contentPrefsProvider).adultContentMode;
      return await engine.search(
        arg.query,
        type: arg.type,
        page: page,
        adultMode: adultMode,
        genres: arg.genres,
        tags: arg.tags,
      );
    } else {
      final allSources = await ref.read(
        arg.type == MediaType.ANIME
            ? availableAnimeSourcesProvider.future
            : availableMangaSourcesProvider.future,
      );
      final activeSources = allSources
          .where(
            (s) => (arg.source != null
                ? s.id == arg.source
                : prefs.activeSources.contains(s.id)),
          )
          .toList();

      if (activeSources.isEmpty) {
        return const PaginatedResult(items: [], hasNextPage: false);
      }

      // If viewing a specific source without query/genres/tags, try trending first
      if (arg.source != null &&
          arg.query.isEmpty &&
          arg.genres.isEmpty &&
          arg.tags.isEmpty &&
          activeSources.length == 1) {
        final info = activeSources.first;
        try {
          final source = arg.type == MediaType.ANIME
              ? ref.read(animeSourceProvider(info))
              : ref.read(mangaSourceProvider(info));
          List<UnifiedMedia> items = [];
          try {
            items = await source.getTrending(page: page);
          } catch (_) {}
          if (items.isEmpty) {
            items = await source.search('', arg.type, page: page);
          }
          return PaginatedResult(
            items: items,
            hasNextPage: items.isNotEmpty && items.length >= 8,
          );
        } catch (_) {
          return const PaginatedResult(items: [], hasNextPage: false);
        }
      }

      final futures = activeSources.map((info) async {
        try {
          final source = arg.type == MediaType.ANIME
              ? ref.read(animeSourceProvider(info))
              : ref.read(mangaSourceProvider(info));
          return await source.search(
            arg.query,
            arg.type,
            page: page,
            genres: arg.genres,
            tags: arg.tags,
          );
        } catch (_) {
          return <UnifiedMedia>[];
        }
      });

      final results = await Future.wait(futures);
      final merged = results.expand((list) => list).toList();

      return PaginatedResult(
        items: merged,
        hasNextPage: merged.isNotEmpty && merged.length >= 8,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (_isFetchingNextPage) return;
    final currentData = state.value;
    if (currentData == null || !currentData.hasNextPage) return;

    _isFetchingNextPage = true;
    _currentPage++;

    try {
      final newPageResult = await _fetchPage(_currentPage);
      final newItems = newPageResult.items;
      final hasNext = newPageResult.hasNextPage && newItems.isNotEmpty;
      state = AsyncData(
        PaginatedResult(
          items: [...currentData.items, ...newItems],
          hasNextPage: hasNext,
        ),
      );
    } catch (e, _) {
      _currentPage--;
      state = AsyncData(
        PaginatedResult(items: currentData.items, hasNextPage: false),
      );
    } finally {
      _isFetchingNextPage = false;
    }
  }
}
