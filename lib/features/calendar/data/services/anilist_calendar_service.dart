import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/domain/services/calendar_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class AnilistCalendarService implements CalendarService {
  final HTTP _http;

  AnilistCalendarService(this._http);

  @override
  CalendarSource get source => CalendarSource.anilist;

  @override
  List<MediaType> get supportedMediaTypes => const [MediaType.ANIME];

  static const String _endpoint = 'https://graphql.anilist.co';

  static const String _airingQuery = r'''
query ($airingAt_greater: Int, $airingAt_lesser: Int, $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
    }
    airingSchedules(
      airingAt_greater: $airingAt_greater,
      airingAt_lesser: $airingAt_lesser,
      sort: TIME
    ) {
      id
      airingAt
      timeUntilAiring
      episode
      mediaId
      media {
        id
        idMal
        title {
          romaji
          english
          native
          userPreferred
        }
        coverImage {
          extraLarge
          large
          medium
          color
        }
        bannerImage
        format
        status
        episodes
        duration
        genres
        averageScore
        popularity
        isAdult
        description(asHtml: false)
      }
    }
  }
}
''';

  @override
  Future<List<CalendarEntry>> getScheduleForDate(
    DateTime date, {
    MediaType mediaType = MediaType.ANIME,
    bool includeAdult = false,
  }) async {
    final startOfDay =
        DateTime(
          date.year,
          date.month,
          date.day,
        ).toUtc().millisecondsSinceEpoch ~/
        1000;
    final endOfDay =
        DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).toUtc().millisecondsSinceEpoch ~/
        1000;

    return _fetchRange(startOfDay, endOfDay, includeAdult: includeAdult);
  }

  @override
  Future<Map<DateTime, List<CalendarEntry>>> getWeekSchedule(
    DateTime startOfWeek, {
    MediaType mediaType = MediaType.ANIME,
    bool includeAdult = false,
  }) async {
    final start =
        DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        ).toUtc().millisecondsSinceEpoch ~/
        1000;
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final end =
        DateTime(
          endOfWeek.year,
          endOfWeek.month,
          endOfWeek.day,
          23,
          59,
          59,
        ).toUtc().millisecondsSinceEpoch ~/
        1000;

    final allEntries = await _fetchRange(
      start,
      end,
      includeAdult: includeAdult,
    );

    final Map<DateTime, List<CalendarEntry>> weekMap = {};
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      weekMap[dayKey] = [];
    }

    for (final entry in allEntries) {
      if (entry.airingAt != null) {
        final localDate = entry.airingAt!.toLocal();
        final dayKey = DateTime(localDate.year, localDate.month, localDate.day);
        if (weekMap.containsKey(dayKey)) {
          weekMap[dayKey]!.add(entry);
        } else {
          weekMap[dayKey] = [entry];
        }
      }
    }

    return weekMap;
  }

  Future<List<CalendarEntry>> _fetchRange(
    int greaterTimestamp,
    int lesserTimestamp, {
    required bool includeAdult,
  }) async {
    final List<CalendarEntry> results = [];
    int page = 1;
    bool hasNextPage = true;

    while (hasNextPage && page <= 4) {
      final response = await _http.post(
        _endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        cacheDuration: const Duration(hours: 6),
        body: jsonEncode({
          'query': _airingQuery,
          'variables': {
            'airingAt_greater': greaterTimestamp,
            'airingAt_lesser': lesserTimestamp,
            'page': page,
            'perPage': 50,
          },
        }),
      );

      final json = response.json as Map<String, dynamic>;
      final data = json['data']?['Page'];
      if (data == null) break;

      hasNextPage = data['pageInfo']?['hasNextPage'] == true;
      final schedules = (data['airingSchedules'] as List<dynamic>?) ?? [];

      for (final s in schedules) {
        final media = s['media'] as Map<String, dynamic>?;
        if (media == null) continue;

        final isAdult = media['isAdult'] == true;
        if (!includeAdult && isAdult) continue;

        final titleMap = media['title'] as Map<String, dynamic>?;
        final title =
            titleMap?['userPreferred'] ??
            titleMap?['english'] ??
            titleMap?['romaji'] ??
            'Unknown';
        final englishTitle = titleMap?['english'] as String?;
        final romajiTitle = titleMap?['romaji'] as String?;
        final nativeTitle = titleMap?['native'] as String?;

        final coverImageMap = media['coverImage'] as Map<String, dynamic>?;
        final coverUrl =
            coverImageMap?['extraLarge'] ??
            coverImageMap?['large'] ??
            coverImageMap?['medium'];
        final hexString = coverImageMap?['color'] as String?;
        Color? color;
        if (hexString != null && hexString.startsWith('#')) {
          final cleanHex = hexString.replaceFirst('#', '');
          if (cleanHex.length == 6) {
            color = Color(int.parse('FF$cleanHex', radix: 16));
          }
        }

        final airingAtSec = s['airingAt'] as int?;
        final airingAt = airingAtSec != null
            ? DateTime.fromMillisecondsSinceEpoch(
                airingAtSec * 1000,
                isUtc: true,
              ).toLocal()
            : null;

        final timeUntilAiring = s['timeUntilAiring'] as int?;
        final episode = s['episode'] as int?;
        final totalEpisodes = media['episodes'] as int?;
        final format = media['format'] as String?;
        final status = media['status'] as String?;
        final genres =
            (media['genres'] as List<dynamic>?)?.cast<String>() ?? [];
        final avgScore = (media['averageScore'] as num?)?.toDouble();
        final score = avgScore != null ? avgScore / 10.0 : null;
        final synopsis = media['description'] as String?;

        results.add(
          CalendarEntry(
            id: s['id'].toString(),
            mediaId: media['id'].toString(),
            title: title,
            englishTitle: englishTitle,
            romajiTitle: romajiTitle,
            nativeTitle: nativeTitle,
            coverUrl: coverUrl,
            bannerUrl: media['bannerImage'] as String?,
            colorHex: color,
            episode: episode,
            totalEpisodes: totalEpisodes,
            airingAt: airingAt,
            timeUntilAiringSeconds: timeUntilAiring,
            format: format,
            status: status,
            genres: genres,
            score: score,
            synopsis: synopsis,
            source: CalendarSource.anilist,
            isAdult: isAdult,
            rawExtra: s,
          ),
        );
      }

      page++;
    }

    return results;
  }
}
