import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

@immutable
class SearchArgs {
  final String query;
  final String? category;
  final MediaType type;
  final List<String> genres;
  final List<String> tags;
  final String? source;
  final SearchSort sort;
  final SearchStatusFilter status;
  final SearchFormatFilter format;

  const SearchArgs({
    this.query = '',
    this.category,
    this.type = MediaType.ANIME,
    this.genres = const [],
    this.tags = const [],
    this.source,
    this.sort = SearchSort.popularity,
    this.status = SearchStatusFilter.all,
    this.format = SearchFormatFilter.all,
  });

  bool get isEmpty =>
      query.isEmpty &&
      (category == null || category!.isEmpty) &&
      genres.isEmpty &&
      tags.isEmpty &&
      source == null &&
      sort == SearchSort.popularity &&
      status == SearchStatusFilter.all &&
      format == SearchFormatFilter.all;

  SearchArgs copyWith({
    String? query,
    String? category,
    bool clearCategory = false,
    MediaType? type,
    List<String>? genres,
    List<String>? tags,
    String? source,
    bool clearSource = false,
    SearchSort? sort,
    SearchStatusFilter? status,
    SearchFormatFilter? format,
  }) {
    return SearchArgs(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      type: type ?? this.type,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      source: clearSource ? null : (source ?? this.source),
      sort: sort ?? this.sort,
      status: status ?? this.status,
      format: format ?? this.format,
    );
  }

  @override
  int get hashCode => Object.hash(
    query,
    category,
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

    return query == other.query &&
        category == other.category &&
        type == other.type &&
        source == other.source &&
        sort == other.sort &&
        status == other.status &&
        format == other.format &&
        const ListEquality().equals(genres, other.genres) &&
        const ListEquality().equals(tags, other.tags);
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
    if (arg.isEmpty) return null;
    return _fetchPage(1);
  }

  Future<PaginatedResult<UnifiedMedia>> _fetchPage(int page) async {
    final prefs = ref.read(discoveryPrefsProvider);

    // If this is a category browse request (e.g. Popular, Top Rated, Trending, or source feed)
    if (arg.category != null && arg.category!.isNotEmpty) {
      return _fetchCategoryPage(page, prefs);
    }

    // Standard search / browse request
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
      return _fetchSourceSearchPage(page, prefs);
    }
  }

  Future<PaginatedResult<UnifiedMedia>> _fetchCategoryPage(
    int page,
    DiscoveryPrefs prefs,
  ) async {
    final category = arg.category!;

    if (prefs.mode == MetadataMode.tracker) {
      final engine = ref.read(metadataSourceProvider);
      final adultMode = ref.read(contentPrefsProvider).adultContentMode;
      final matchedCategory = TrackerCategory.tryFromId(category);

      if (matchedCategory != null) {
        return await engine.getCategoryItems(
          matchedCategory,
          type: arg.type,
          page: page,
          cacheDuration: const Duration(hours: 6),
          adultMode: adultMode,
        );
      } else {
        return await engine.search(
          '',
          type: arg.type,
          page: page,
          genres: [category],
          adultMode: adultMode,
          cacheDuration: const Duration(hours: 6),
        );
      }
    } else {
      final allSources = await ref.read(
        arg.type.availableSourcesProvider.future,
      );
      if (!ref.mounted) {
        return const PaginatedResult(items: [], hasNextPage: false);
      }

      final activeSources = allSources
          .where((s) => prefs.activeSources.contains(s.id))
          .toList();

      if (activeSources.isEmpty) {
        return const PaginatedResult(items: [], hasNextPage: false);
      }

      // Check if this is a "More" tap on a trending feed generated by home_feed_provider
      final mediaTypeName = arg.type.displayName;
      final targetSourceInfo = activeSources.firstWhereOrNull((s) {
        final expectedTitle = '${s.name} ($mediaTypeName)';
        return expectedTitle == category;
      });

      if (targetSourceInfo != null) {
        try {
          final source = arg.type.usesAnimeSources
              ? ref.read(animeSourceProvider(targetSourceInfo))
              : ref.read(mangaSourceProvider(targetSourceInfo));
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

      // Fallback: Perform an actual text search across all active sources
      final futures = activeSources.map((info) async {
        try {
          final source = arg.type.usesAnimeSources
              ? ref.read(animeSourceProvider(info))
              : ref.read(mangaSourceProvider(info));
          return await source.search(category, arg.type, page: page);
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

  Future<PaginatedResult<UnifiedMedia>> _fetchSourceSearchPage(
    int page,
    DiscoveryPrefs prefs,
  ) async {
    final allSources = await ref.read(arg.type.availableSourcesProvider.future);
    if (!ref.mounted) {
      return const PaginatedResult(items: [], hasNextPage: false);
    }

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
        final source = arg.type.usesAnimeSources
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
        final source = arg.type.usesAnimeSources
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
            return fmt.contains('OVA') ||
                fmt.contains('ONA') ||
                fmt.contains('SPECIAL');
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
        filtered.sort(
          (a, b) => a.title.availableTitle.toLowerCase().compareTo(
            b.title.availableTitle.toLowerCase(),
          ),
        );
        break;
      case SearchSort.alphabeticalZA:
        filtered.sort(
          (a, b) => b.title.availableTitle.toLowerCase().compareTo(
            a.title.availableTitle.toLowerCase(),
          ),
        );
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
      if (!ref.mounted) return;
      final newItems = newPageResult.items;
      final hasNext = newPageResult.hasNextPage && newItems.isNotEmpty;
      state = AsyncData(
        PaginatedResult(
          items: [...currentData.items, ...newItems],
          hasNextPage: hasNext,
        ),
      );
    } catch (e, _) {
      if (!ref.mounted) return;
      _currentPage--;
      state = AsyncData(
        PaginatedResult(items: currentData.items, hasNextPage: false),
      );
    } finally {
      _isFetchingNextPage = false;
    }
  }
}
