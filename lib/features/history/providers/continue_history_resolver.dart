import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

final continueHistoryResolverProvider = Provider(
  (ref) => ContinueHistoryResolver(ref),
);

class ContinueHistoryResolver {
  final Ref ref;

  const ContinueHistoryResolver(this.ref);

  Future<dynamic> resolve(HistoryEntry entry) async {
    final mediaType = MediaType.values.firstWhere(
      (e) => e.id == entry.mediaType,
      orElse: () => MediaType.ANIME,
    );

    // 1. Fetch preferences
    final prefState = await ref.read(
      mediaPreferenceProvider(
        MediaArgs.fromTitle(entry.mediaTitle, type: mediaType),
      ).future,
    );

    // 2. Determine Source and Provider ID
    SourceInfo? sourceInfo;
    String? providerId;

    if (prefState.hasExplicitSource && prefState.matchedMediaId != null) {
      sourceInfo = prefState.sourceInfo;
      providerId = prefState.matchedMediaId!;
    } else if (entry.sourceId != null && entry.providerId != null) {
      final availableSourcesInfo = await ref.read(
        mediaType == MediaType.ANIME
            ? availableAnimeSourcesProvider.future
            : availableMangaSourcesProvider.future,
      );
      sourceInfo =
          availableSourcesInfo.firstWhereOrNull(
            (s) => s.id == entry.sourceId && s.name == entry.sourceName,
          ) ??
          availableSourcesInfo.firstWhereOrNull((s) => s.id == entry.sourceId);
      providerId = entry.providerId!;
    }

    if (sourceInfo == null || providerId == null) {
      final matchState = await ref.read(
        matchedMediaProvider(
          MediaArgs.fromTitle(entry.mediaTitle, type: mediaType),
        ).future,
      );
      if (matchState.matchedMedia == null) {
        throw Exception('Could not resolve media source.');
      }
      sourceInfo = matchState.sourceInfo;
      providerId = matchState.matchedMedia!.id;
    }

    // 3. Fetch episodes/chapters
    final episodesState = await ref.read(
      sourceEpisodesProvider((
        providerId: providerId,
        sourceId: sourceInfo.id,
        sourceType: sourceInfo.type,
        type: mediaType,
      )).future,
    );

    // 4. Find the target episode/chapter
    UnifiedEpisode? targetEpisode = episodesState.episodes.firstWhereOrNull(
      (e) => e.number == entry.itemNumber,
    );

    if (mediaType == MediaType.ANIME) {
      // 5. Determine progress (advance to next if fully watched)
      final threshold = ref.read(trackingPrefsProvider).syncThreshold;
      final isWatched =
          entry.total > 0 && entry.progress >= entry.total * threshold;
      Duration? startPosition = Duration(milliseconds: entry.progress);

      if (isWatched && targetEpisode != null) {
        final currentIndex = episodesState.episodes.indexOf(targetEpisode);
        if (currentIndex != -1 &&
            currentIndex + 1 < episodesState.episodes.length) {
          targetEpisode = episodesState.episodes[currentIndex + 1];
        }
        startPosition = null; // Reset position
      }

      if (targetEpisode == null) {
        throw Exception('Episode not found in the selected source.');
      }

      return PlayerModeOnline(
        media: UnifiedMedia(
          id: entry.mediaId,
          idMal: entry.mediaIdMal,
          providerId: providerId,
          externalIds: entry.externalIds,
          cover: entry.cover,
          banner: entry.banner,
          type: mediaType,
          title: MediaTitle(english: entry.mediaTitle),
        ),
        episode: targetEpisode,
        sourceInfo: sourceInfo,
        startPosition: startPosition,
      );
    } else {
      if (targetEpisode == null) {
        throw Exception('Chapter not found in the selected source.');
      }

      return ReaderModeOnline(
        media: UnifiedMedia(
          id: entry.mediaId,
          idMal: entry.mediaIdMal,
          externalIds: entry.externalIds,
          cover: entry.cover,
          banner: entry.banner,
          sourceId: sourceInfo.id,
          sourceName: sourceInfo.name,
          providerId: providerId,
          type: mediaType,
          title: MediaTitle(english: entry.mediaTitle),
        ),
        episode: targetEpisode,
        sourceInfo: sourceInfo,
        startPosition: entry.progress > 0 && entry.progress <= entry.total
            ? entry.progress
            : 1,
      );
    }
  }
}
