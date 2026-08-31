import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/features/calendar/data/calendar_service_factory.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/providers/calendar_prefs_provider.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/database_provider.dart';

class SelectedWeekStartNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  void setWeekStart(DateTime date) {
    state = DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void jumpToCurrentWeek() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }
}

final selectedWeekStartProvider =
    NotifierProvider<SelectedWeekStartNotifier, DateTime>(
      SelectedWeekStartNotifier.new,
    );

class CalendarSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final calendarSearchQueryProvider =
    NotifierProvider<CalendarSearchQueryNotifier, String>(
      CalendarSearchQueryNotifier.new,
    );

typedef WeekScheduleParams = ({
  CalendarSource source,
  DateTime weekStart,
  MediaType mediaType,
});

final calendarWeekScheduleProvider = FutureProvider.autoDispose
    .family<Map<DateTime, List<CalendarEntry>>, WeekScheduleParams>((
      ref,
      params,
    ) async {
      var didCancel = false;
      ref.onDispose(() => didCancel = true);
      await Future.delayed(const Duration(milliseconds: 350));
      if (didCancel) {
        throw Exception('Cancelled');
      }

      final factory = ref.watch(calendarServiceFactoryProvider);
      final service = factory.getService(params.source);
      return service.getWeekSchedule(
        params.weekStart,
        mediaType: params.mediaType,
      );
    });

final calendarLibraryIdsProvider = StreamProvider<Set<String>>((ref) {
  final isar = ref.watch(databaseProvider);
  return isar.libraryEntrys.where().watch(fireImmediately: true).map((entries) {
    final set = <String>{};
    for (final e in entries) {
      if (e.providerId.isNotEmpty) {
        set.add(e.providerId.toLowerCase());
      }
      if (e.title.isNotEmpty) {
        set.add(e.title.toLowerCase().trim());
      }
      final ext = e.externalIds;
      if (ext.anilist != null && ext.anilist!.isNotEmpty) {
        set.add(ext.anilist!.toLowerCase());
      }
      if (ext.mal != null && ext.mal!.isNotEmpty) {
        set.add(ext.mal!.toLowerCase());
      }
      if (ext.simkl != null && ext.simkl!.isNotEmpty) {
        set.add(ext.simkl!.toLowerCase());
      }
      if (ext.kitsu != null && ext.kitsu!.isNotEmpty) {
        set.add(ext.kitsu!.toLowerCase());
      }
    }
    return set;
  });
});

final filteredWeekScheduleProvider =
    Provider<AsyncValue<Map<DateTime, List<CalendarEntry>>>>((ref) {
      final weekStart = ref.watch(selectedWeekStartProvider);
      final prefs = ref.watch(calendarPrefsProvider);
      final query = ref.watch(calendarSearchQueryProvider).toLowerCase().trim();
      final libraryIds = ref.watch(calendarLibraryIdsProvider).value ?? {};

      final rawWeekAsync = ref.watch(
        calendarWeekScheduleProvider((
          source: prefs.source,
          weekStart: weekStart,
          mediaType: prefs.mediaType,
        )),
      );

      return rawWeekAsync.whenData((weekMap) {
        final Map<DateTime, List<CalendarEntry>> filteredMap = {};

        for (int i = 0; i < 7; i++) {
          final dayDate = weekStart.add(Duration(days: i));
          final dayKey = DateTime(dayDate.year, dayDate.month, dayDate.day);
          final rawList = weekMap[dayKey] ?? [];

          final sorted = List<CalendarEntry>.from(rawList)
            ..sort((a, b) {
              if (a.airingAt != null && b.airingAt != null) {
                return a.airingAt!.compareTo(b.airingAt!);
              }
              if (a.airingAt != null) return -1;
              if (b.airingAt != null) return 1;
              return a.title.compareTo(b.title);
            });

          final filteredList = sorted.where((entry) {
            if (prefs.hideAired && entry.isAired) {
              return false;
            }

            final inLibrary =
                libraryIds.contains(entry.mediaId.toLowerCase()) ||
                libraryIds.contains(entry.title.toLowerCase().trim()) ||
                (entry.englishTitle != null &&
                    libraryIds.contains(
                      entry.englishTitle!.toLowerCase().trim(),
                    )) ||
                (entry.romajiTitle != null &&
                    libraryIds.contains(
                      entry.romajiTitle!.toLowerCase().trim(),
                    ));

            if (prefs.onlyInLibrary && !inLibrary) {
              return false;
            }

            if (query.isNotEmpty) {
              final matchTitle = entry.title.toLowerCase().contains(query);
              final matchEn =
                  entry.englishTitle?.toLowerCase().contains(query) ?? false;
              final matchRomaji =
                  entry.romajiTitle?.toLowerCase().contains(query) ?? false;
              if (!matchTitle && !matchEn && !matchRomaji) {
                return false;
              }
            }

            return true;
          }).toList();

          filteredMap[dayKey] = filteredList;
        }

        return filteredMap;
      });
    });
