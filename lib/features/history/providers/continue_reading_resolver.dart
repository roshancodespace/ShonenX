import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

final continueReadingResolverProvider = Provider(
  (ref) => ContinueReadingResolver(ref),
);

class ContinueReadingResolver {
  final Ref ref;

  const ContinueReadingResolver(this.ref);

  Future<ReaderModeOnline> resolve(ReadHistoryEntry entry) async {
    // 1. Fetch preferences
    final prefState = await ref.read(
      mediaPreferenceProvider(
        MediaArgs.fromTitle(entry.mangaTitle, type: MediaType.MANGA),
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
        availableMangaSourcesProvider.future,
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
          MediaArgs.fromTitle(entry.mangaTitle, type: MediaType.MANGA),
        ).future,
      );
      if (matchState.matchedMedia == null) {
        throw Exception('Could not resolve media source.');
      }
      sourceInfo = matchState.sourceInfo;
      providerId = matchState.matchedMedia!.id;
    }

    // 3. Fetch chapters
    final chaptersState = await ref.read(
      sourceEpisodesProvider((
        providerId: providerId,
        sourceId: sourceInfo.id,
        sourceType: sourceInfo.type,
        type: MediaType.MANGA,
      )).future,
    );

    // 4. Find the target chapter
    final chapter = chaptersState.episodes.firstWhereOrNull(
      (e) => e.number == entry.chapterNumber,
    );

    if (chapter == null) {
      throw Exception('Chapter not found in the selected source.');
    }

    // 5. Return ReaderMode
    return ReaderModeOnline(
      media: UnifiedMedia(
        id: entry.mangaId,
        idMal: entry.mangaIdMal,
        externalIds: entry.externalIds,
        cover: entry.cover,
        banner: entry.banner,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
        providerId: providerId,
        type: MediaType.MANGA,
        title: MediaTitle(english: entry.mangaTitle),
      ),
      episode: chapter,
      sourceInfo: sourceInfo,
      startPosition:
          entry.positionPage > 0 && entry.positionPage <= entry.totalPages
          ? entry.positionPage
          : 1,
    );
  }
}
