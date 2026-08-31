import 'package:flutter/material.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class CalendarEntry {
  final String id;
  final String mediaId;
  final String title;
  final String? englishTitle;
  final String? romajiTitle;
  final String? nativeTitle;
  final String? coverUrl;
  final String? bannerUrl;
  final Color? colorHex;
  final int? episode;
  final int? totalEpisodes;
  final DateTime? airingAt;
  final int? timeUntilAiringSeconds;
  final String? format;
  final String? status;
  final List<String> genres;
  final double? score;
  final String? synopsis;
  final String? broadcastTime;
  final CalendarSource source;
  final MediaType mediaType;
  final bool isAdult;
  final Map<String, dynamic>? rawExtra;

  const CalendarEntry({
    required this.id,
    required this.mediaId,
    required this.title,
    this.englishTitle,
    this.romajiTitle,
    this.nativeTitle,
    this.coverUrl,
    this.bannerUrl,
    this.colorHex,
    this.episode,
    this.totalEpisodes,
    this.airingAt,
    this.timeUntilAiringSeconds,
    this.format,
    this.status,
    this.genres = const [],
    this.score,
    this.synopsis,
    this.broadcastTime,
    required this.source,
    this.mediaType = MediaType.ANIME,
    this.isAdult = false,
    this.rawExtra,
  });

  bool get isAired => airingAt != null && airingAt!.isBefore(DateTime.now());

  Duration? get timeUntilAiring {
    if (airingAt == null) return null;
    final diff = airingAt!.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  String get displayTitle {
    if (englishTitle != null && englishTitle!.trim().isNotEmpty) {
      return englishTitle!;
    }
    if (romajiTitle != null && romajiTitle!.trim().isNotEmpty) {
      return romajiTitle!;
    }
    return title;
  }

  UnifiedMedia toUnifiedMedia() {
    return UnifiedMedia(
      id: mediaId,
      type: mediaType,
      sourceId: source.name,
      sourceName: source.displayName,
      title: MediaTitle(
        english: englishTitle ?? title,
        romaji: romajiTitle ?? title,
        native: nativeTitle,
      ),
      cover: coverUrl,
      banner: bannerUrl,
      score: score,
      description: synopsis,
      genres: genres,
      status: status,
      format: format,
      episodes: totalEpisodes,
      isAdult: isAdult,
      airingAt: airingAt,
      nextEpisode: episode,
      externalIds: MediaExternalIds(
        anilist: source == CalendarSource.anilist ? mediaId : null,
        mal: source == CalendarSource.mal ? mediaId : null,
        simkl: source == CalendarSource.simkl ? mediaId : null,
        kitsu: source == CalendarSource.kitsu ? mediaId : null,
      ),
    );
  }
}
