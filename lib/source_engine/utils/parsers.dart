import 'dart:convert';

import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';

class MediaInfo {
  final String title;
  final String id;
  final int? tmdbId;
  final String tvtype;
  final String year;
  final int season;
  final int episode;
  final DateTime? firstAired;
  final bool isAnime;
  final bool isBollywood;
  final bool isAsian;
  final bool isCartoon;
  final String? imdbId;
  final int? imdbSeason;
  final int? imdbEpisode;
  final bool isKitsu;
  final int? anilistId;
  final int? malId;
  final int? kitsuId;

  MediaInfo({
    required this.title,
    required this.id,
    this.tmdbId,
    required this.tvtype,
    required this.year,
    required this.season,
    required this.episode,
    this.firstAired,
    required this.isAnime,
    required this.isBollywood,
    required this.isAsian,
    required this.isCartoon,
    this.imdbId,
    this.imdbSeason,
    this.imdbEpisode,
    required this.isKitsu,
    this.anilistId,
    this.malId,
    this.kitsuId,
  });

  factory MediaInfo.fromMap(Map<String, dynamic> map) {
    return MediaInfo(
      title: map['title'] ?? '',
      id: map['id'] ?? '',
      tmdbId: map['tmdbId'],
      tvtype: map['tvtype'] ?? '',
      year: map['year'] ?? '',
      season: map['season']?.toInt() ?? 0,
      episode: map['episode']?.toInt() ?? 0,
      firstAired: map['firstAired'] != null
          ? DateTime.tryParse(map['firstAired'])
          : null,
      isAnime: map['isAnime'] ?? false,
      isBollywood: map['isBollywood'] ?? false,
      isAsian: map['isAsian'] ?? false,
      isCartoon: map['isCartoon'] ?? false,
      imdbId: map['imdb_id'],
      imdbSeason: map['imdbSeason']?.toInt(),
      imdbEpisode: map['imdbEpisode']?.toInt(),
      isKitsu: map['isKitsu'] ?? false,
      anilistId: map['anilistId']?.toInt(),
      malId: map['malId']?.toInt(),
      kitsuId: map['kitsuId']?.toInt(),
    );
  }
}

MediaInfo? parseMediaInfoString(String jsonString) {
  try {
    String cleanString = jsonString.replaceAll(r'\"', '"');

    final Map<String, dynamic> data = jsonDecode(cleanString);

    return MediaInfo.fromMap(data);
  } catch (e) {
    return null;
  }
}

extension DEpisodeX on DEpisode {
  MediaInfo? toMediaInfo() {
    return parseMediaInfoString(url ?? '{}');
  }
}

extension DMediaX on DMedia {
  MediaInfo? toMediaInfo() {
    return parseMediaInfoString(url ?? '{}');
  }
}

