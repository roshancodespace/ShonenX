import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/shared/models/unified_media.dart';

abstract class CalendarService {
  CalendarSource get source;

  List<MediaType> get supportedMediaTypes => source.supportedMediaTypes;

  Future<List<CalendarEntry>> getScheduleForDate(
    DateTime date, {
    MediaType mediaType = MediaType.ANIME,
    bool includeAdult = false,
  });

  Future<Map<DateTime, List<CalendarEntry>>> getWeekSchedule(
    DateTime startOfWeek, {
    MediaType mediaType = MediaType.ANIME,
    bool includeAdult = false,
  });
}
