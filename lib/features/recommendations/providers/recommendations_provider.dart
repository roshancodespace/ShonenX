import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/features/discovery/providers/discovery_feed_provider.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/recommendations/data/liked_anime_repository.dart';
import 'package:shonenx/features/recommendations/domain/models/liked_anime.dart';
import 'package:shonenx/features/recommendations/domain/models/recommended_anime.dart';
import 'package:shonenx/features/recommendations/domain/models/user_taste_profile.dart';
import 'package:shonenx/features/recommendations/engine/recommendation_engine.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

final likedAnimeRepositoryProvider = Provider<LikedAnimeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LikedAnimeRepository(prefs);
});

class LikedAnimeNotifier extends Notifier<Map<String, LikedAnime>> {
  late LikedAnimeRepository _repo;

  @override
  Map<String, LikedAnime> build() {
    _repo = ref.watch(likedAnimeRepositoryProvider);
    return _repo.loadAll();
  }

  bool isLiked(String id) {
    return state.containsKey(id);
  }

  Future<bool> toggleLike(UnifiedMedia media) async {
    final nowLiked = await _repo.toggle(media);
    state = _repo.loadAll();
    ref.invalidate(userTasteProfileProvider);
    ref.invalidate(recommendedAnimeFeedProvider);
    return nowLiked;
  }

  Future<void> addLike(UnifiedMedia media) async {
    final item = LikedAnime.fromUnifiedMedia(media);
    await _repo.add(item);
    state = _repo.loadAll();
    ref.invalidate(userTasteProfileProvider);
    ref.invalidate(recommendedAnimeFeedProvider);
  }

  Future<void> removeLike(String id) async {
    await _repo.remove(id);
    state = _repo.loadAll();
    ref.invalidate(userTasteProfileProvider);
    ref.invalidate(recommendedAnimeFeedProvider);
  }
}

final likedAnimeProvider =
    NotifierProvider<LikedAnimeNotifier, Map<String, LikedAnime>>(
      LikedAnimeNotifier.new,
    );

final userTasteProfileProvider = FutureProvider<UserTasteProfile>((ref) async {
  final likedMap = ref.watch(likedAnimeProvider);
  final isar = ref.watch(databaseProvider);

  final genreAffinities = <String, double>{};
  final tagAffinities = <String, double>{};
  final seedAnime = <UnifiedMedia>[];
  final excludedIds = <String>{};

  int likedCount = 0;
  int completedCount = 0;
  int watchingCount = 0;
  int planningCount = 0;
  int droppedCount = 0;

  // 1. Process Liked Anime (+4.0 weight)
  for (final liked in likedMap.values) {
    likedCount++;
    excludedIds.add(liked.id);
    final media = liked.toUnifiedMedia();
    seedAnime.add(media);

    for (final g in liked.genres) {
      genreAffinities[g] = (genreAffinities[g] ?? 0.0) + 4.0;
    }
    for (final t in liked.tags) {
      tagAffinities[t] = (tagAffinities[t] ?? 0.0) + 2.0;
    }
  }

  // 2. Process Local Isar Library Entries
  try {
    final libraryEntries = await isar.libraryEntrys.where().findAll();
    for (final entry in libraryEntries) {
      final status = entry.status.toLowerCase();
      final id = entry.providerId;
      if (id.isNotEmpty) {
        // Exclude watched, watching, or dropped from recommendations
        if (status == 'completed' ||
            status == 'watching' ||
            status == 'dropped') {
          excludedIds.add(id);
        }
      }

      double weight = 0.0;
      if (status == 'completed') {
        completedCount++;
        weight = 3.5;
        // Also treat completed as potential seed
        seedAnime.add(
          UnifiedMedia(
            id: entry.providerId,
            title: MediaTitle(english: entry.title, userPreferred: entry.title),
            cover: entry.cover,
            format: entry.format,
            score: entry.score,
          ),
        );
      } else if (status == 'watching') {
        watchingCount++;
        weight = 2.5;
      } else if (status == 'planning') {
        planningCount++;
        weight = 2.0;
      } else if (status == 'dropped') {
        droppedCount++;
        weight = -4.0; // Penalty
      }
    }
  } catch (_) {}

  return UserTasteProfile(
    genreAffinities: genreAffinities,
    tagAffinities: tagAffinities,
    seedAnime: seedAnime,
    excludedIds: excludedIds,
    likedCount: likedCount,
    completedCount: completedCount,
    watchingCount: watchingCount,
    planningCount: planningCount,
    droppedCount: droppedCount,
  );
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return const RecommendationEngine();
});

final recommendedAnimeFeedProvider =
    FutureProvider.family<List<RecommendedAnime>, MediaType>((
      ref,
      mediaType,
    ) async {
      final profile = await ref.watch(userTasteProfileProvider.future);
      final tracker = ref.watch(metadataSourceProvider);
      final adultMode = ref.watch(contentPrefsProvider).adultContentMode;
      final engine = ref.watch(recommendationEngineProvider);

      // If user has no likes or library signals, return high-rated trending items
      if (!profile.hasAnySignals) {
        try {
          final trending = await tracker.getCategoryItems(
            TrackerCategory.trending,
            type: mediaType,
            adultMode: adultMode,
            cacheDuration: const Duration(hours: 6),
          );
          return trending.items
              .map(
                (m) => RecommendedAnime(
                  media: m,
                  matchScore: (m.score ?? 8.0),
                  reason: 'Trending recommendation to get you started',
                ),
              )
              .toList();
        } catch (_) {
          return const [];
        }
      }

      final candidates = <UnifiedMedia>[];
      final seedReasons = <String, String>{};

      // 1. Expand Direct Seed Recommendations (from liked and completed anime)
      for (final seed in profile.seedAnime) {
        final recs = seed.recommendations;
        if (recs != null && recs.isNotEmpty) {
          for (final rec in recs) {
            if (rec.id.isNotEmpty && !profile.excludedIds.contains(rec.id)) {
              candidates.add(rec);
              seedReasons[rec.id] =
                  'Because you liked ${seed.title.availableTitle}';
            }
          }
        }
      }

      // 2. Query candidates from user's top positive genres
      final topGenres = profile.topPositiveGenres.take(3).toList();
      for (final genre in topGenres) {
        try {
          final genreItems = await ref.watch(
            genreFeedProvider((type: mediaType, genre: genre)).future,
          );
          for (final item in genreItems) {
            if (!profile.excludedIds.contains(item.id)) {
              candidates.add(item);
            }
          }
        } catch (_) {}
      }

      // 3. Add Top Rated items as high-quality candidate fallback
      try {
        final topRated = await tracker.getCategoryItems(
          TrackerCategory.topRated,
          type: mediaType,
          adultMode: adultMode,
          cacheDuration: const Duration(hours: 12),
        );
        for (final item in topRated.items) {
          if (!profile.excludedIds.contains(item.id)) {
            candidates.add(item);
          }
        }
      } catch (_) {}

      // 4. Rank, deduplicate, and assign reasons
      return engine.rankCandidates(
        profile: profile,
        candidates: candidates,
        seedReasons: seedReasons,
      );
    });

final recommendedMediaFeedProvider =
    FutureProvider.family<List<UnifiedMedia>, MediaType>((
      ref,
      mediaType,
    ) async {
      final recommended = await ref.watch(
        recommendedAnimeFeedProvider(mediaType).future,
      );
      return recommended.map((r) => r.media).toList();
    });
