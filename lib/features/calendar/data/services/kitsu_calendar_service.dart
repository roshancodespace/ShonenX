import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/domain/services/calendar_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class KitsuCalendarService implements CalendarService {
  final HTTP _http;

  KitsuCalendarService(this._http);

  @override
  CalendarSource get source => CalendarSource.kitsu;

  @override
  List<MediaType> get supportedMediaTypes => const [MediaType.ANIME];

  static const String _baseUrl = 'https://kitsu.app/api/edge';
  static const String _fallbackUrl = 'https://kitsu.io/api/edge';

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

    final allCurrent = await _fetchCurrentAiring(includeAdult: includeAdult);

    for (int i = 0; i < allCurrent.length; i++) {
      final entry = allCurrent[i];
      if (entry.airingAt != null) {
        final targetWeekday = entry.airingAt!.weekday;
        final matchingDays = weekMap.keys.where(
          (d) => d.weekday == targetWeekday,
        );
        if (matchingDays.isNotEmpty) {
          final dayKey = matchingDays.first;
          weekMap[dayKey]!.add(entry);
        } else {
          final fallbackDay = weekMap.keys.elementAt(i % 7);
          weekMap[fallbackDay]!.add(entry);
        }
      } else {
        final fallbackDay = weekMap.keys.elementAt(i % 7);
        weekMap[fallbackDay]!.add(entry);
      }
    }

    return weekMap;
  }

  Future<List<CalendarEntry>> _fetchCurrentAiring({
    required bool includeAdult,
  }) async {
    final List<CalendarEntry> results = [];
    final urls = [
      '$_baseUrl/anime?filter[status]=current&page[limit]=20&sort=-userCount',
      '$_baseUrl/anime?filter[status]=current&page[limit]=20&page[offset]=20&sort=-userCount',
      '$_fallbackUrl/anime?filter[status]=current&page[limit]=20&sort=-userCount',
    ];

    for (final url in urls) {
      try {
        final response = await _http.get(
          url,
          headers: {
            'Accept': 'application/vnd.api+json',
            'Content-Type': 'application/vnd.api+json',
          },
          cacheDuration: const Duration(hours: 12),
        );

        final json = response.json as Map<String, dynamic>;
        final dataList = (json['data'] as List<dynamic>?) ?? [];

        for (final item in dataList) {
          if (item is Map<String, dynamic>) {
            final entry = _mapKitsuItem(item);
            if (!includeAdult && entry.isAdult) continue;
            if (!results.any((r) => r.id == entry.id)) {
              results.add(entry);
            }
          }
        }
      } catch (_) {}
    }

    return results;
  }

  CalendarEntry _mapKitsuItem(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final attrs = item['attributes'] as Map<String, dynamic>? ?? {};

    final canonicalTitle = (attrs['canonicalTitle'] as String?) ?? 'Unknown';
    final titles = attrs['titles'] as Map<String, dynamic>?;
    final englishTitle =
        titles?['en'] as String? ?? titles?['en_us'] as String?;
    final romajiTitle = titles?['en_jp'] as String?;
    final japaneseTitle = titles?['ja_jp'] as String?;

    final posterImage = attrs['posterImage'] as Map<String, dynamic>?;
    final coverUrl =
        posterImage?['large'] as String? ??
        posterImage?['original'] as String? ??
        posterImage?['medium'] as String?;

    final coverImage = attrs['coverImage'] as Map<String, dynamic>?;
    final bannerUrl =
        coverImage?['large'] as String? ?? coverImage?['original'] as String?;

    final startDateStr = attrs['startDate'] as String?;
    DateTime? airingAt;
    if (startDateStr != null) {
      airingAt = DateTime.tryParse(startDateStr);
    }

    final avgRatingStr = attrs['averageRating'] as String?;
    final double? score = avgRatingStr != null
        ? (double.tryParse(avgRatingStr) != null
              ? double.parse(avgRatingStr) / 10.0
              : null)
        : null;

    final synopsis = attrs['synopsis'] as String?;
    final totalEpisodes = attrs['episodeCount'] as int?;
    final format = (attrs['subtype'] as String?)?.toUpperCase();
    final status = attrs['status'] as String?;

    return CalendarEntry(
      id: id,
      mediaId: id,
      title: canonicalTitle,
      englishTitle: englishTitle,
      romajiTitle: romajiTitle,
      nativeTitle: japaneseTitle,
      coverUrl: coverUrl,
      bannerUrl: bannerUrl,
      totalEpisodes: totalEpisodes,
      airingAt: airingAt,
      format: format,
      status: status,
      score: score,
      synopsis: synopsis,
      source: CalendarSource.kitsu,
      isAdult: attrs['nsfw'] == true,
      rawExtra: item,
    );
  }
}
