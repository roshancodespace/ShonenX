import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/utils/parsers.dart';
import 'base_source_adapter.dart';

class AnimeSourceAdapter extends BaseSourceAdapter implements AnimeSource {
  AnimeSourceAdapter({required super.sourceInfo, required super.source});

  @override
  final log = AppLogger.scope(AnimeSourceAdapter);

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    final methodLog = log.child('getEpisodes');
    try {
      final detail = await getRawDetail(animeId);

      methodLog.d('episodes=${detail.episodes?.length ?? 0}');

      return (detail.episodes ?? []).map(_mapToUnifiedEpisode).toList();
    } catch (e, st) {
      methodLog.e('getEpisodes failed', e, st);
      return [];
    }
  }

  UnifiedEpisode _mapToUnifiedEpisode(bridge.DEpisode e) {
    int? season;
    double? episodeNumber;
    String? cleanTitle;

    final name = e.name?.trim() ?? '';

    // 1. Parse from Title (e.g. S0:E46, S2:E12, S02E12, Season 2 Episode 12, 2x12)
    if (name.isNotEmpty) {
      // Pattern 1: S<season>:E<episode> or S<season>E<episode> at start
      final sPattern = RegExp(
        r'^\s*S(\d+)[:\s\-._]*E(?:P)?[:\s\-._]*(\d+(?:\.\d+)?)(?:\s*[:-]\s*|\s+|$)(.*)',
        caseSensitive: false,
      ).firstMatch(name);

      if (sPattern != null) {
        season = int.tryParse(sPattern.group(1)!);
        episodeNumber = double.tryParse(sPattern.group(2)!);
        final remaining = sPattern.group(3)?.trim() ?? '';
        cleanTitle = _cleanRemainingTitle(remaining);
      } else {
        // Pattern 2: Season <season> Episode <episode>
        final seasonPattern = RegExp(
          r'^\s*Season\s*(\d+)[:\s\-._]*(?:Episode|Ep\.?|E)?[:\s\-._]*(\d+(?:\.\d+)?)(?:\s*[:-]\s*|\s+|$)(.*)',
          caseSensitive: false,
        ).firstMatch(name);

        if (seasonPattern != null) {
          season = int.tryParse(seasonPattern.group(1)!);
          episodeNumber = double.tryParse(seasonPattern.group(2)!);
          final remaining = seasonPattern.group(3)?.trim() ?? '';
          cleanTitle = _cleanRemainingTitle(remaining);
        } else {
          // Pattern 3: <season>x<episode> (e.g. 2x12)
          final xPattern = RegExp(
            r'^\s*(\d{1,2})x(\d{1,4}(?:\.\d+)?)(?:\s*[:-]\s*|\s+|$)(.*)',
            caseSensitive: false,
          ).firstMatch(name);

          if (xPattern != null) {
            season = int.tryParse(xPattern.group(1)!);
            episodeNumber = double.tryParse(xPattern.group(2)!);
            final remaining = xPattern.group(3)?.trim() ?? '';
            cleanTitle = _cleanRemainingTitle(remaining);
          } else {
            // Pattern 4: Embedded S<season>E<episode> anywhere in title
            final embeddedPattern = RegExp(
              r'(?:\b|_)S(\d+)[:\s\-._]*E(?:P)?[:\s\-._]*(\d+(?:\.\d+)?)\b',
              caseSensitive: false,
            ).firstMatch(name);

            if (embeddedPattern != null) {
              season = int.tryParse(embeddedPattern.group(1)!);
              episodeNumber = double.tryParse(embeddedPattern.group(2)!);
              final cleaned = name
                  .replaceAll(embeddedPattern.group(0)!, '')
                  .trim();
              cleanTitle = _cleanRemainingTitle(cleaned);
            } else {
              // Pattern 5: Episode <ep> at start (no season in title)
              final epOnlyPattern = RegExp(
                r'^\s*(?:Episode|Ep\.?)\s*(\d+(?:\.\d+)?)(?:\s*[:-]\s*|\s+|$)(.*)',
                caseSensitive: false,
              ).firstMatch(name);

              if (epOnlyPattern != null) {
                episodeNumber = double.tryParse(epOnlyPattern.group(1)!);
                final remaining = epOnlyPattern.group(2)?.trim() ?? '';
                cleanTitle = _cleanRemainingTitle(remaining);
              } else {
                cleanTitle = name;
              }
            }
          }
        }
      }
    }

    // 2. Parse from sortMap
    if (e.sortMap != null) {
      if (season == null && e.sortMap!.containsKey('season')) {
        final sStr = e.sortMap!['season']?.trim();
        if (sStr != null && sStr.isNotEmpty) {
          season = int.tryParse(sStr);
        }
      }
      if (episodeNumber == null &&
          (e.sortMap!.containsKey('episode') ||
              e.sortMap!.containsKey('episodeNumber'))) {
        final epStr = (e.sortMap!['episode'] ?? e.sortMap!['episodeNumber'])
            ?.trim();
        if (epStr != null && epStr.isNotEmpty) {
          episodeNumber = double.tryParse(epStr);
        }
      }
    }

    // 3. Parse from URL (e.g. :0:46 or /season/2/episode/12)
    final url = e.url;
    if (url != null && url.isNotEmpty) {
      if (season == null || episodeNumber == null) {
        final stremioMatch = RegExp(
          r':(\d+):(\d+(?:\.\d+)?)(?:\.json|[/?#&]|$)',
        ).firstMatch(url);
        if (stremioMatch != null) {
          season ??= int.tryParse(stremioMatch.group(1)!);
          episodeNumber ??= double.tryParse(stremioMatch.group(2)!);
        }
      }
      if (season == null || episodeNumber == null) {
        final pathMatch = RegExp(
          r'[/?&_-]season[/?&=_-](\d+)[/?&_-]ep(?:isode)?[/?&=_-](\d+(?:\.\d+)?)',
          caseSensitive: false,
        ).firstMatch(url);
        if (pathMatch != null) {
          season ??= int.tryParse(pathMatch.group(1)!);
          episodeNumber ??= double.tryParse(pathMatch.group(2)!);
        }
      }
    }

    // 4. Parse season from toMediaInfo() or scanlator if still null
    season ??= e.toMediaInfo()?.season;
    season ??= _parseSeasonFromScanlator(e.scanlator);

    // 5. Resolve Episode Number from raw episodeNumber if needed
    if (episodeNumber == null) {
      final rawNum = e.episodeNumber.trim();

      // If season is known and rawNum is in format "<season>.<episode>", e.g. "3.2" for S3 E2 or "0.46" for S0 E46
      if (season != null && rawNum.contains('.')) {
        final prefix = '$season.';
        if (rawNum.startsWith(prefix)) {
          final epSub = rawNum.substring(prefix.length);
          final parsedSub = double.tryParse(epSub);
          if (parsedSub != null) {
            episodeNumber = parsedSub;
          }
        }
      }

      // If season is still null, check if rawNum encodes season.episode (e.g. 3.2, 1.9, 0.46)
      if (season == null && rawNum.contains('.')) {
        final parts = rawNum.split('.');
        if (parts.length == 2) {
          final s = int.tryParse(parts[0]);
          final ep = double.tryParse(parts[1]);
          if (s != null && ep != null && s >= 0 && ep > 0) {
            season = s;
            episodeNumber = ep;
          }
        }
      }

      episodeNumber ??= double.tryParse(rawNum) ?? 0.0;
    }

    return UnifiedEpisode(
      id: '${e.url ?? ''}|${e.episodeNumber}',
      season: season,
      title: (cleanTitle == null || cleanTitle.trim().isEmpty)
          ? null
          : cleanTitle.trim(),
      number: episodeNumber,
      scanlator: e.scanlator,
      uploadDate: e.dateUpload,
    );
  }

  String? _cleanRemainingTitle(String text) {
    var cleaned = text.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^[:\-–—\s]+'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  int? _parseSeasonFromScanlator(String? scanlator) {
    if (scanlator == null || scanlator.isEmpty) return null;
    final match = RegExp(
      r'season\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(scanlator);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    final methodLog = log.child('getServers');
    methodLog.i('episodeId=$episodeId');
    return [VideoServer(id: 'auto', name: 'Default')];
  }

  @override
  Future<List<VideoStream>> getSources(
    String episodeId,
    VideoServer server,
  ) async {
    final methodLog = log.child('getSources');
    try {
      methodLog.i('episodeId=$episodeId server=${server.name}');
      final parts = episodeId.split('|');
      final url = parts[0];
      final epNum = parts.length > 1 ? parts[1] : '1';

      final videos = await source.methods.getVideoList(
        bridge.DEpisode(url: url, episodeNumber: epNum),
      );

      methodLog.d('streams=${videos.length}');

      methodLog.w(videos.first.extraData.toString());

      return videos.map((e) {
        String finalUrl = e.url;

        final finalHeaders = {
          ...(e.headers ?? {}),
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36',
        };

        return VideoStream(
          url: finalUrl,
          quality: e.title ?? e.quality,
          headers: finalHeaders,
          subtitles: (e.subtitles ?? [])
              .map((s) => SubtitleTrack(url: s.file!, language: s.label!))
              .toList(),
        );
      }).toList();
    } catch (e, st) {
      methodLog.e('getSources failed', e, st);
      return [];
    }
  }

  @override
  Future<List<String>> getFilterGenres() async {
    return [];
  }

  @override
  Future<List<String>> getFilterTags() async {
    return [];
  }
}
