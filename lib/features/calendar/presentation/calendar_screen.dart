import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/calendar/presentation/widgets/calendar_day_row.dart';
import 'package:shonenx/features/calendar/presentation/widgets/calendar_source_selector.dart';
import 'package:shonenx/features/calendar/presentation/widgets/calendar_week_header.dart';
import 'package:shonenx/features/calendar/providers/calendar_prefs_provider.dart';
import 'package:shonenx/features/calendar/providers/calendar_schedule_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

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
    final radius = GlobalUI.uiRoundness;
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
        Material(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(radius * 0.7),
          child: InkWell(
            onTap: () => CalendarSourceSelectorSheet.show(context),
            borderRadius: BorderRadius.circular(radius * 0.7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius * 0.7),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  prefs.source.trackerType.getIconWidget(
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    prefs.source.displayName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        if (!isCurrentWeek)
          IconButton(
            icon: const Icon(Icons.today_rounded, size: 20),
            tooltip: 'This Week',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).jumpToCurrentWeek();
            },
          ),
        IconButton(
          icon: Icon(
            _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
            size: 20,
          ),
          tooltip: _isSearchOpen ? 'Close Search' : 'Search Anime',
          visualDensity: VisualDensity.compact,
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
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(calendarSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
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
                        FilledButton.icon(
                          onPressed: () {
                            ref.invalidate(
                              calendarWeekScheduleProvider((
                                source: prefs.source,
                                weekStart: weekStart,
                                mediaType: prefs.mediaType,
                              )),
                            );
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
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
