import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/features/calendar/providers/calendar_prefs_provider.dart';
import 'package:shonenx/features/calendar/providers/calendar_schedule_provider.dart';

class CalendarWeekHeader extends ConsumerWidget {
  const CalendarWeekHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final prefs = ref.watch(calendarPrefsProvider);
    final prefsNotifier = ref.read(calendarPrefsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

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

    final startStr = DateFormat('MMM d').format(weekStart);
    final endStr = weekStart.month == weekEnd.month
        ? DateFormat('d, yyyy').format(weekEnd)
        : DateFormat('MMM d, yyyy').format(weekEnd);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$startStr – $endStr',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: cs.onSurface,
                    ),
                  ),
                  if (isCurrentWeek) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CURRENT WEEK',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    tooltip: 'Previous Week',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      ref
                          .read(selectedWeekStartProvider.notifier)
                          .previousWeek();
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    tooltip: 'Next Week',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      ref.read(selectedWeekStartProvider.notifier).nextWeek();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (prefs.source.supportedMediaTypes.length > 1) ...[
                  ...prefs.source.supportedMediaTypes.map((type) {
                    final isSelected = prefs.mediaType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          type.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        onSelected: (v) {
                          if (v) prefsNotifier.setMediaType(type);
                        },
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                  Container(
                    height: 18,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 4),
                ],
                FilterChip(
                  label: const Text(
                    'In Library',
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: prefs.onlyInLibrary,
                  onSelected: (v) => prefsNotifier.setOnlyInLibrary(v),
                  avatar: Icon(
                    prefs.onlyInLibrary
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 14,
                  ),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text(
                    'Hide Aired',
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: prefs.hideAired,
                  onSelected: (v) => prefsNotifier.setHideAired(v),
                  avatar: Icon(
                    prefs.hideAired
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_outlined,
                    size: 14,
                  ),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
