import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

class SearchArgs {
  final String query;
  final MediaType type;
  final List<String> genres;
  final List<String> tags;
  final String? source;
  final SearchSort sort;
  final SearchStatusFilter status;
  final SearchFormatFilter format;

  const SearchArgs({
    required this.query,
    required this.type,
    this.genres = const [],
    this.tags = const [],
    this.source,
    this.sort = SearchSort.popularity,
    this.status = SearchStatusFilter.all,
    this.format = SearchFormatFilter.all,
  });

  @override
  int get hashCode => Object.hash(
    query,
    type,
    source,
    sort,
    status,
    format,
    Object.hashAll(genres),
    Object.hashAll(tags),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchArgs) return false;

    if (query != other.query ||
        type != other.type ||
        source != other.source ||
        sort != other.sort ||
        status != other.status ||
        format != other.format) {
      return false;
    }

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
        arg.source == null &&
        arg.sort == SearchSort.popularity &&
        arg.status == SearchStatusFilter.all &&
        arg.format == SearchFormatFilter.all) {
      return null;
    }
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
        sort: arg.sort,
        status: arg.status,
        format: arg.format,
      );
    } else {
      final allSources = await ref.read(
        arg.type.availableSourcesProvider.future,
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
          final source =
              (arg.type == MediaType.ANIME ||
                  arg.type == MediaType.MOVIE ||
                  arg.type == MediaType.TV)
              ? ref.read(animeSourceProvider(info))
              : ref.read(mangaSourceProvider(info));
          List<UnifiedMedia> items = [];
          try {
            items = await source.getTrending(page: page);
          } catch (_) {}
          if (items.isEmpty) {
            items = await source.search('', arg.type, page: page);
          }
          items = _applySourceFilters(items);
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
          final source =
              (arg.type == MediaType.ANIME ||
                  arg.type == MediaType.MOVIE ||
                  arg.type == MediaType.TV)
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
      var merged = results.expand((list) => list).toList();
      merged = _applySourceFilters(merged);

      return PaginatedResult(
        items: merged,
        hasNextPage: merged.isNotEmpty && merged.length >= 8,
      );
    }
  }

  List<UnifiedMedia> _applySourceFilters(List<UnifiedMedia> items) {
    var filtered = items;

    // Apply Status Filter
    if (arg.status != SearchStatusFilter.all) {
      filtered = filtered.where((item) {
        final st = item.status?.toLowerCase() ?? '';
        if (arg.status == SearchStatusFilter.releasing) {
          return st.contains('releasing') || st.contains('ongoing');
        } else if (arg.status == SearchStatusFilter.finished) {
          return st.contains('finished') || st.contains('completed');
        } else if (arg.status == SearchStatusFilter.notYetReleased) {
          return st.contains('not_yet_released') ||
              st.contains('upcoming') ||
              st.contains('unreleased');
        }
        return true;
      }).toList();
    }

    // Apply Format Filter
    if (arg.format != SearchFormatFilter.all) {
      filtered = filtered.where((item) {
        final fmt = item.format?.toUpperCase() ?? '';
        switch (arg.format) {
          case SearchFormatFilter.tv:
            return fmt.contains('TV');
          case SearchFormatFilter.movie:
            return fmt.contains('MOVIE');
          case SearchFormatFilter.ova:
            return fmt.contains('OVA') || fmt.contains('ONA') || fmt.contains('SPECIAL');
          case SearchFormatFilter.manga:
            return fmt.contains('MANGA');
          case SearchFormatFilter.oneShot:
            return fmt.contains('ONE_SHOT') || fmt.contains('ONE SHOT');
          case SearchFormatFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply Client Sort
    switch (arg.sort) {
      case SearchSort.alphabeticalAZ:
        filtered.sort((a, b) => a.title.availableTitle.toLowerCase().compareTo(b.title.availableTitle.toLowerCase()));
        break;
      case SearchSort.alphabeticalZA:
        filtered.sort((a, b) => b.title.availableTitle.toLowerCase().compareTo(a.title.availableTitle.toLowerCase()));
        break;
      case SearchSort.newest:
        filtered.sort((a, b) => (b.season ?? '').compareTo(a.season ?? ''));
        break;
      case SearchSort.oldest:
        filtered.sort((a, b) => (a.season ?? '').compareTo(b.season ?? ''));
        break;
      case SearchSort.popularity:
        // default order
        break;
    }

    return filtered;
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
