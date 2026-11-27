import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/presentation/widgets/calendar_day_row.dart';
import 'package:shonenx/features/calendar/presentation/widgets/calendar_source_selector.dart';
import 'package:shonenx/features/calendar/presentation/widgets/calendar_week_header.dart';
import 'package:shonenx/features/calendar/providers/calendar_prefs_provider.dart';
import 'package:shonenx/features/calendar/providers/calendar_schedule_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/app_icon_button.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/m3e_dropdown.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _isSearchOpen = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(calendarSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;
    final prefs = ref.watch(calendarPrefsProvider);
    final weekStart = ref.watch(selectedWeekStartProvider);
    final weekScheduleAsync = ref.watch(filteredWeekScheduleProvider);

    final now = DateTime.now();
    final currentWeekMonday = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final isCurrentWeek =
        weekStart.year == currentWeekMonday.year &&
        weekStart.month == currentWeekMonday.month &&
        weekStart.day == currentWeekMonday.day;

    return AppScaffold(
      title: 'Airing Calendar',
      actions: [
        M3eDropdown<CalendarSource>(
          value: prefs.source,
          isExpanded: false,
          items: CalendarSource.values
              .map(
                (source) => DropdownMenuItem<CalendarSource>(
                  value: source,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      source.trackerType.getIconWidget(
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        source.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (source) {
            if (source != null) {
              ref.read(calendarPrefsProvider.notifier).setSource(source);
            }
          },
        ),
        const SizedBox(width: 6),
        if (!isCurrentWeek) ...[
          AppIconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'This Week',
            radius: isClassic ? 10.0 : 999.0,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).jumpToCurrentWeek();
            },
          ),
          const SizedBox(width: 4),
        ],
        AppIconButton(
          icon: Icon(
            _isSearchOpen ? CupertinoIcons.xmark : CupertinoIcons.search,
          ),
          tooltip: _isSearchOpen ? 'Close Search' : 'Search Anime',
          radius: isClassic ? 10.0 : 999.0,
          backgroundColor: _isSearchOpen
              ? cs.primaryContainer
              : cs.surfaceContainerHighest.withValues(alpha: 0.45),
          foregroundColor: _isSearchOpen ? cs.onPrimaryContainer : cs.onSurface,
          onPressed: () {
            setState(() {
              _isSearchOpen = !_isSearchOpen;
              if (!_isSearchOpen) {
                _searchController.clear();
                ref.read(calendarSearchQueryProvider.notifier).setQuery('');
              }
            });
          },
        ),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          if (_isSearchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  ref.read(calendarSearchQueryProvider.notifier).setQuery(val);
                },
                decoration: InputDecoration(
                  hintText: 'Search anime release...',
                  prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? AppIconButton(
                          icon: const Icon(CupertinoIcons.xmark_circle_fill),
                          size: 32,
                          radius: 999,
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(calendarSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      isClassic ? 10.0 : 999.0,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          const CalendarWeekHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  calendarWeekScheduleProvider((
                    source: prefs.source,
                    weekStart: weekStart,
                    mediaType: prefs.mediaType,
                  )),
                );
              },
              child: weekScheduleAsync.when(
                loading: () => ListView.builder(
                  itemCount: 7,
                  padding: const EdgeInsets.only(top: 4, bottom: 40),
                  itemBuilder: (context, index) {
                    final dummyDate = weekStart.add(Duration(days: index));
                    return CalendarDayRow(
                      date: dummyDate,
                      entries: const [],
                      isLoading: true,
                      source: prefs.source,
                    );
                  },
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: cs.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load schedule from ${prefs.source.displayName}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          variant: AppButtonVariant.tonal,
                          onPressed: () {
                            ref.invalidate(
                              calendarWeekScheduleProvider((
                                source: prefs.source,
                                weekStart: weekStart,
                                mediaType: prefs.mediaType,
                              )),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                data: (weekMap) {
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: 7,
                    padding: const EdgeInsets.only(top: 4, bottom: 40),
                    itemBuilder: (context, index) {
                      final dayDate = weekStart.add(Duration(days: index));
                      final dayKey = DateTime(
                        dayDate.year,
                        dayDate.month,
                        dayDate.day,
                      );
                      final dayEntries = weekMap[dayKey] ?? [];

                      return CalendarDayRow(
                        key: ValueKey(
                          '${prefs.source.name}_${dayKey.toIso8601String()}',
                        ),
                        date: dayDate,
                        entries: dayEntries,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
