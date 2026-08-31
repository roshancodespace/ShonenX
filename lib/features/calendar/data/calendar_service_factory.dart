import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/calendar/data/services/anilist_calendar_service.dart';
import 'package:shonenx/features/calendar/data/services/kitsu_calendar_service.dart';
import 'package:shonenx/features/calendar/data/services/mal_calendar_service.dart';
import 'package:shonenx/features/calendar/data/services/simkl_calendar_service.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/domain/services/calendar_service.dart';

final calendarServiceFactoryProvider = Provider<CalendarServiceFactory>((ref) {
  final http = ref.watch(httpClientProvider);
  return CalendarServiceFactory(http);
});

class CalendarServiceFactory {
  final HTTP _http;
  final Map<CalendarSource, CalendarService> _instances = {};

  CalendarServiceFactory(this._http);

  CalendarService getService(CalendarSource source) {
    return _instances.putIfAbsent(source, () {
      return switch (source) {
        CalendarSource.anilist => AnilistCalendarService(_http),
        CalendarSource.mal => MalCalendarService(_http),
        CalendarSource.simkl => SimklCalendarService(_http),
        CalendarSource.kitsu => KitsuCalendarService(_http),
      };
    });
  }
}
