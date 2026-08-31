import 'dart:io';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/domain/services/calendar_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class MalCalendarService implements CalendarService {
  final HTTP _http;

  MalCalendarService(this._http);

  @override
  CalendarSource get source => CalendarSource.mal;

  @override
  List<MediaType> get supportedMediaTypes => const [MediaType.ANIME];

  static String get _clientId => Platform.isWindows || Platform.isLinux
      ? Env.MAL_CLIENT_ID_LIST.last
      : Env.MAL_CLIENT_ID_LIST.first;

  static String _getSeason(int month) {
    return switch (month) {
      1 || 2 || 3 => 'winter',
      4 || 5 || 6 => 'spring',
      7 || 8 || 9 => 'summer',
      _ => 'fall',
    };
  }

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

    try {
      final year = startOfWeek.year;
      final season = _getSeason(startOfWeek.month);
      final url =
          'https://api.myanimelist.net/v2/anime/season/$year/$season?fields=broadcast,main_picture,title,alternative_titles,mean,status,num_episodes,genres,synopsis,media_type,nsfw&limit=500';

      final response = await _http.get(
        url,
        headers: {'X-MAL-CLIENT-ID': _clientId},
        cacheDuration: const Duration(hours: 12),
      );

      final json = response.json as Map<String, dynamic>;
      final dataList = (json['data'] as List<dynamic>?) ?? [];

      for (final item in dataList) {
        final node = item['node'] as Map<String, dynamic>?;
        if (node == null) continue;

        final isNsfw = node['nsfw'] != null && node['nsfw'] != 'white';
        if (!includeAdult && isNsfw) continue;

        final broadcast = node['broadcast'] as Map<String, dynamic>?;
        final dayStr = (broadcast?['day_of_the_week'] as String?)
            ?.toLowerCase();

        int? targetWeekday = switch (dayStr) {
          'monday' => DateTime.monday,
          'tuesday' => DateTime.tuesday,
          'wednesday' => DateTime.wednesday,
          'thursday' => DateTime.thursday,
          'friday' => DateTime.friday,
          'saturday' => DateTime.saturday,
          'sunday' => DateTime.sunday,
          _ => null,
        };

        if (targetWeekday != null) {
          final matchingDays = weekMap.keys.where(
            (d) => d.weekday == targetWeekday,
          );
          if (matchingDays.isNotEmpty) {
            final matchingDay = matchingDays.first;
            final entry = _mapMalNode(node, matchingDay);
            weekMap[matchingDay]!.add(entry);
          }
        }
      }

      if (weekMap.values.any((list) => list.isNotEmpty)) {
        return weekMap;
      }
    } catch (_) {}

    try {
      final jikanUrl = 'https://api.jikan.moe/v4/seasons/now?limit=25';
      final response = await _http.get(
        jikanUrl,
        cacheDuration: const Duration(hours: 12),
      );
      final json = response.json as Map<String, dynamic>;
      final dataList = (json['data'] as List<dynamic>?) ?? [];

      for (final item in dataList) {
        final broadcast = item['broadcast'] as Map<String, dynamic>?;
        final dayStr = (broadcast?['day'] as String?)?.toLowerCase();

        int? targetWeekday;
        if (dayStr != null) {
          if (dayStr.contains('mon')) targetWeekday = DateTime.monday;
          if (dayStr.contains('tue')) targetWeekday = DateTime.tuesday;
          if (dayStr.contains('wed')) targetWeekday = DateTime.wednesday;
          if (dayStr.contains('thu')) targetWeekday = DateTime.thursday;
          if (dayStr.contains('fri')) targetWeekday = DateTime.friday;
          if (dayStr.contains('sat')) targetWeekday = DateTime.saturday;
          if (dayStr.contains('sun')) targetWeekday = DateTime.sunday;
        }

        if (targetWeekday != null) {
          final matchingDays = weekMap.keys.where(
            (d) => d.weekday == targetWeekday,
          );
          if (matchingDays.isNotEmpty) {
            final matchingDay = matchingDays.first;
            final entry = _mapJikanItem(item, matchingDay);
            weekMap[matchingDay]!.add(entry);
          }
        }
      }
    } catch (_) {}

    return weekMap;
  }

  CalendarEntry _mapMalNode(Map<String, dynamic> node, DateTime targetDate) {
    final id = node['id']?.toString() ?? '';
    final title = (node['title'] as String?) ?? 'Unknown';
    final alt = node['alternative_titles'] as Map<String, dynamic>?;
    final englishTitle = alt?['en'] as String?;
    final japaneseTitle = alt?['ja'] as String?;

    final mainPic = node['main_picture'] as Map<String, dynamic>?;
    final coverUrl = mainPic?['large'] ?? mainPic?['medium'];

    final broadcast = node['broadcast'] as Map<String, dynamic>?;
    final timeStr = broadcast?['start_time'] as String?;

    DateTime? airingAt;
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final jstDateTime = DateTime.utc(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      ).subtract(const Duration(hours: 9));
      airingAt = jstDateTime.toLocal();
    } else {
      airingAt = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        12,
        0,
      );
    }

    final genresList = (node['genres'] as List<dynamic>?) ?? [];
    final genres = genresList
        .map((g) => g['name'] as String?)
        .where((n) => n != null && n.isNotEmpty)
        .cast<String>()
        .toList();

    final score = (node['mean'] as num?)?.toDouble();
    final synopsis = node['synopsis'] as String?;
    final totalEpisodes = node['num_episodes'] as int?;
    final format = (node['media_type'] as String?)?.toUpperCase();
    final status = node['status'] as String?;

    final timeUntil = airingAt.isAfter(DateTime.now())
        ? airingAt.difference(DateTime.now()).inSeconds
        : null;

    return CalendarEntry(
      id: id,
      mediaId: id,
      title: title,
      englishTitle: englishTitle,
      romajiTitle: title,
      nativeTitle: japaneseTitle,
      coverUrl: coverUrl,
      totalEpisodes: totalEpisodes,
      airingAt: airingAt,
      timeUntilAiringSeconds: timeUntil,
      format: format,
      status: status,
      genres: genres,
      score: score,
      synopsis: synopsis,
      source: CalendarSource.mal,
      rawExtra: node,
    );
  }

  CalendarEntry _mapJikanItem(Map<String, dynamic> item, DateTime targetDate) {
    final malId = item['mal_id']?.toString() ?? '';
    final title = (item['title'] as String?) ?? 'Unknown';
    final englishTitle = item['title_english'] as String?;
    final japaneseTitle = item['title_japanese'] as String?;

    final images = item['images'] as Map<String, dynamic>?;
    final webp = images?['webp'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final coverUrl =
        webp?['large_image_url'] ??
        webp?['image_url'] ??
        jpg?['large_image_url'] ??
        jpg?['image_url'];

    final broadcast = item['broadcast'] as Map<String, dynamic>?;
    final timeStr = broadcast?['time'] as String?;

    DateTime? airingAt;
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final jstDateTime = DateTime.utc(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      ).subtract(const Duration(hours: 9));
      airingAt = jstDateTime.toLocal();
    } else {
      airingAt = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        12,
        0,
      );
    }

    final genresList = (item['genres'] as List<dynamic>?) ?? [];
    final genres = genresList
        .map((g) => g['name'] as String?)
        .where((n) => n != null && n.isNotEmpty)
        .cast<String>()
        .toList();

    final score = (item['score'] as num?)?.toDouble();
    final synopsis = item['synopsis'] as String?;
    final totalEpisodes = item['episodes'] as int?;
    final format = item['type'] as String?;
    final status = item['status'] as String?;

    final timeUntil = airingAt.isAfter(DateTime.now())
        ? airingAt.difference(DateTime.now()).inSeconds
        : null;

    return CalendarEntry(
      id: malId,
      mediaId: malId,
      title: title,
      englishTitle: englishTitle,
      romajiTitle: title,
      nativeTitle: japaneseTitle,
      coverUrl: coverUrl,
      totalEpisodes: totalEpisodes,
      airingAt: airingAt,
      timeUntilAiringSeconds: timeUntil,
      format: format,
      status: status,
      genres: genres,
      score: score,
      synopsis: synopsis,
      source: CalendarSource.mal,
      rawExtra: item,
    );
  }
}
