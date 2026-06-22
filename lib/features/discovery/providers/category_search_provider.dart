import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/core/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

class CategorySearchArgs {
  final String category;
  final MediaType type;

  const CategorySearchArgs({required this.category, required this.type});

  @override
  int get hashCode => Object.hash(category, type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySearchArgs &&
          other.category == category &&
          other.type == type;
}

final categorySearchProvider = AsyncNotifierProvider.autoDispose
    .family<
      CategorySearchNotifier,
      PaginatedResult<UnifiedMedia>?,
      CategorySearchArgs
    >(CategorySearchNotifier.new, name: 'categorySearchProvider');

class CategorySearchNotifier
    extends AsyncNotifier<PaginatedResult<UnifiedMedia>?> {
  int _currentPage = 1;
  bool _isFetchingNextPage = false;
  CategorySearchArgs arg;

  CategorySearchNotifier(this.arg);

  @override
  Future<PaginatedResult<UnifiedMedia>?> build() async {
    _currentPage = 1;
    _isFetchingNextPage = false;
    if (arg.category.isEmpty) return null;
    return _fetchPage(1);
  }

  Future<PaginatedResult<UnifiedMedia>> _fetchPage(int page) async {
    final prefs = ref.read(discoveryPrefsProvider);

    if (prefs.mode == MetadataMode.tracker) {
      final engine = ref.read(metadataSourceProvider);
      final adultMode = ref.read(contentPrefsProvider).adultContentMode;
      return arg.category.toLowerCase().contains('trending')
          ? await engine.getTrending(
              type: arg.type,
              page: page,
              cacheDuration: const Duration(seconds: 30),
              adultMode: adultMode,
            )
          : const PaginatedResult<UnifiedMedia>(items: [], hasNextPage: false);
    } else {
      final allSources = await ref.read(
        arg.type == MediaType.ANIME
            ? availableAnimeSourcesProvider.future
            : availableMangaSourcesProvider.future,
      );
      final activeSources = allSources
          .where((s) => prefs.activeSources.contains(s.id))
          .toList();

      if (activeSources.isEmpty) {
        return const PaginatedResult(items: [], hasNextPage: false);
      }

      final futures = activeSources.map((info) async {
        try {
          final source = arg.type == MediaType.ANIME
              ? ref.read(animeSourceProvider(info))
              : ref.read(mangaSourceProvider(info));
          return await source.search(arg.category, arg.type, page: page);
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
          items: [
            ...{...currentData.items, ...newPageResult.items},
          ],
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
