import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'metadata_tags_provider.dart';

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
        cacheDuration: Duration(hours: 6),
      );

      return result.items;
    });
