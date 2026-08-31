import 'dart:io';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/domain/services/calendar_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class SimklCalendarService implements CalendarService {
  final HTTP _http;

  SimklCalendarService(this._http);

  @override
  CalendarSource get source => CalendarSource.simkl;

  @override
  List<MediaType> get supportedMediaTypes => const [
    MediaType.ANIME,
    MediaType.TV,
    MediaType.MOVIE,
  ];

  static const String _baseUrl = 'https://api.simkl.com';

  static String get _clientId => Platform.isWindows || Platform.isLinux
      ? Env.SIMKL_CLIENT_ID_LIST.last
      : Env.SIMKL_CLIENT_ID_LIST.first;

  Map<String, String> get _headers => {
    'simkl-api-key': _clientId,
    'Content-Type': 'application/json',
  };

  @override
  Future<List<CalendarEntry>> getScheduleForDate(
    DateTime date, {
    MediaType mediaType = MediaType.ANIME,
    bool includeAdult = false,
  }) async {
    final weekSchedule = await getWeekSchedule(
      date.subtract(Duration(days: date.weekday - 1)),
      mediaType: mediaType,
      includeAdult: includeAdult,
    );
    final dayKey = DateTime(date.year, date.month, date.day);
    return weekSchedule[dayKey] ?? [];
  }

  @override
  Future<Map<DateTime, List<CalendarEntry>>> getWeekSchedule(
    DateTime startOfWeek, {
    MediaType mediaType = MediaType.ANIME,
    bool includeAdult = false,
  }) async {
    final Map<DateTime, List<CalendarEntry>> weekMap = {};

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      weekMap[dayKey] = [];
    }

    final List<String> endpoints = switch (mediaType) {
      MediaType.TV => [
        '$_baseUrl/tv/calendar/all?client_id=$_clientId',
        '$_baseUrl/tv/airing?client_id=$_clientId',
      ],
      MediaType.MOVIE => [
        '$_baseUrl/movies/calendar/all?client_id=$_clientId',
        '$_baseUrl/movies/premieres?client_id=$_clientId',
      ],
      _ => [
        '$_baseUrl/anime/calendar/all?client_id=$_clientId',
        '$_baseUrl/anime/airing?client_id=$_clientId',
      ],
    };

    for (final url in endpoints) {
      try {
        final response = await _http.get(
          url,
          headers: _headers,
          cacheDuration: const Duration(hours: 6),
        );
        final json = response.json;

        if (json is List && json.isNotEmpty) {
          for (final item in json) {
            if (item is! Map<String, dynamic>) continue;
            final dateVal =
                item['date'] as String? ??
                item['air_date'] as String? ??
                item['first_aired'] as String?;

            if (dateVal != null) {
              final parsed = DateTime.tryParse(dateVal);
              if (parsed != null) {
                final local = parsed.toLocal();
                final matchingDays = weekMap.keys.where(
                  (d) =>
                      d.year == local.year &&
                      d.month == local.month &&
                      d.day == local.day,
                );

                if (matchingDays.isNotEmpty) {
                  final dayKey = matchingDays.first;
                  final entry = _mapSingleSimklItem(item, local, mediaType);
                  weekMap[dayKey]!.add(entry);
                } else {
                  final weekdayDays = weekMap.keys.where(
                    (d) => d.weekday == local.weekday,
                  );
                  if (weekdayDays.isNotEmpty) {
                    final dayKey = weekdayDays.first;
                    final entry = _mapSingleSimklItem(item, local, mediaType);
                    weekMap[dayKey]!.add(entry);
                  }
                }
              }
            }
          }

          if (weekMap.values.any((list) => list.isNotEmpty)) {
            return weekMap;
          }
        }
      } catch (_) {}
    }

    return weekMap;
  }

  CalendarEntry _mapSingleSimklItem(
    Map<String, dynamic> item,
    DateTime fallbackDate,
    MediaType mediaType,
  ) {
    final show = item['show'] as Map<String, dynamic>? ?? item;
    final ids = show['ids'] as Map<String, dynamic>?;
    final simklId = ids?['simkl']?.toString() ?? show['id']?.toString() ?? '';

    final title = (show['title'] as String?) ?? 'Unknown';
    final poster = (show['poster'] as String?) ?? (item['poster'] as String?);
    final coverUrl = poster != null
        ? (poster.startsWith('http')
              ? poster
              : 'https://simkl.in/posters/${poster}_m.webp')
        : null;

    final dateStr =
        item['date'] as String? ??
        item['air_date'] as String? ??
        item['first_aired'] as String?;
    final airingAt = dateStr != null
        ? (DateTime.tryParse(dateStr)?.toLocal() ?? fallbackDate)
        : fallbackDate;

    final episodeObj = item['episode'] as Map<String, dynamic>?;
    final episodeNumber =
        episodeObj?['episode'] as int? ?? item['episode'] as int?;

    final ratings = show['ratings'] as Map<String, dynamic>?;
    final simklRating = (ratings?['simkl']?['rating'] as num?)?.toDouble();

    final timeUntil = airingAt.isAfter(DateTime.now())
        ? airingAt.difference(DateTime.now()).inSeconds
        : null;

    final defaultFormat = switch (mediaType) {
      MediaType.TV => 'TV',
      MediaType.MOVIE => 'MOVIE',
      _ => 'TV',
    };

    return CalendarEntry(
      id: simklId,
      mediaId: simklId,
      title: title,
      englishTitle: title,
      romajiTitle: title,
      coverUrl: coverUrl,
      episode: episodeNumber,
      airingAt: airingAt,
      timeUntilAiringSeconds: timeUntil,
      format: show['anime_type'] as String? ?? defaultFormat,
      status: show['status'] as String?,
      genres: (show['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      score: simklRating,
      synopsis: show['overview'] as String?,
      source: CalendarSource.simkl,
      mediaType: mediaType,
      rawExtra: item,
    );
  }
}
