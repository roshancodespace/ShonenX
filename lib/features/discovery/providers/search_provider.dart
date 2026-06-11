import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/content_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

class SearchArgs {
  final String query;
  final MediaType type;

  const SearchArgs({required this.query, required this.type});

  @override
  int get hashCode => Object.hash(query, type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchArgs && other.query == query && other.type == type;
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
    if (arg.query.isEmpty) return null;
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
      );
    } else {
      final allSources = await ref.read(availableAnimeSourcesProvider.future);
      final activeSources = allSources
          .where((s) => prefs.activeSources.contains(s.id))
          .toList();

      if (activeSources.isEmpty) {
        return const PaginatedResult(items: [], hasNextPage: false);
      }

      final futures = activeSources.map((info) async {
        try {
          final source = ref.read(animeSourceProvider(info));
          return await source.search(arg.query, arg.type, page: page);
        } catch (_) {
          return <UnifiedMedia>[];
        }
      });

      final results = await Future.wait(futures);
      final merged = results.expand((list) => list).toList();

      return PaginatedResult(items: merged, hasNextPage: false);
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
      state = AsyncData(
        PaginatedResult(
          items: [...currentData.items, ...newPageResult.items],
          hasNextPage: newPageResult.hasNextPage,
        ),
      );
    } catch (e, _) {
      _currentPage--;
    } finally {
      _isFetchingNextPage = false;
    }
  }
}
