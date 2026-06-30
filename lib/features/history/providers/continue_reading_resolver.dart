import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';

final continueReadingResolverProvider = Provider(
  (ref) => ContinueReadingResolver(ref),
);

class ContinueReadingResult {
  final ReaderModeOnline mode;

  const ContinueReadingResult({required this.mode});
}

class ContinueReadingResolver {
  final Ref ref;

  const ContinueReadingResolver(this.ref);

  Future<ContinueReadingResult> resolve(ReadHistoryEntry entry) async {
    final prefState = await ref.read(
      mediaPreferenceProvider(
        MatchArgs(mediaTitle: entry.mangaTitle, type: MediaType.MANGA),
      ).future,
    );

    final sourceInfo = prefState.sourceInfo;

    UnifiedEpisode? chapter;

    if (prefState.manualOverrideId != null) {
      final args = (
        providerId: prefState.manualOverrideId!,
        sourceId: sourceInfo.id,
        type: MediaType.MANGA,
      );

      final episodesState = await ref.read(sourceEpisodesProvider(args).future);

      chapter = episodesState.episodes.firstWhereOrNull(
        (e) => e.number == entry.chapterNumber,
      );
    } else {
      final episodesState = await ref.read(
        episodesListProvider(
          MatchArgs(mediaTitle: entry.mangaTitle, type: MediaType.MANGA),
        ).future,
      );

      chapter = episodesState.episodes.firstWhereOrNull(
        (e) => e.number == entry.chapterNumber,
      );
    }

    if (chapter == null) {
      throw Exception('Chapter not found.');
    }

    return ContinueReadingResult(
      mode: ReaderModeOnline(
        media: UnifiedMedia(
          id: entry.mangaId,
          idMal: entry.mangaIdMal,
          cover: entry.cover,
          banner: entry.banner,
          type: MediaType.MANGA,
          title: MediaTitle(english: entry.mangaTitle),
        ),
        episode: chapter,
        sourceInfo: sourceInfo,
        startPosition:
            entry.positionPage > 0 && entry.positionPage < entry.totalPages
            ? entry.positionPage
            : 1,
      ),
    );
  }
}
