import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

/// Provides a random selection of genres for the discovery feed
final discoveryFeedGenresProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  ref.keepAlive();
  final tagsState = await ref.watch(metadataTagsProvider.future);

  if (tagsState.genres.isEmpty) return [];

  final shuffledGenres = List<String>.from(tagsState.genres)..shuffle();
  return shuffledGenres.take(7).toList();
});

/// Argument for genre feed
typedef GenreFeedArg = ({MediaType type, String genre});

/// Provides the media items for a specific genre row in the feed
final genreFeedProvider = FutureProvider.autoDispose
    .family<List<UnifiedMedia>, GenreFeedArg>((ref, arg) async {
      ref.keepAlive();
      final source = ref.watch(metadataSourceProvider);
      final adultMode = ref.watch(
        contentPrefsProvider.select((p) => p.adultContentMode),
      );

      final result = await source.search(
        '', // empty query
        page: 1,
        type: arg.type,
        genres: [arg.genre],
        adultMode: adultMode,
        cacheDuration: const Duration(hours: 6),
      );

      return result.items;
    });

/// Provides media items for a specific source row in the source discovery feed
final sourceDiscoverFeedProvider = FutureProvider.autoDispose
    .family<List<UnifiedMedia>, ({SourceInfo info, MediaType type})>((
      ref,
      arg,
    ) async {
      ref.keepAlive();
      final source = arg.type == MediaType.ANIME
          ? ref.read(animeSourceProvider(arg.info))
          : ref.read(mangaSourceProvider(arg.info));

      try {
        final trending = await source.getTrending();
        if (trending.isNotEmpty) return trending;
      } catch (_) {}

      return await source.search('', arg.type, page: 1);
    });
