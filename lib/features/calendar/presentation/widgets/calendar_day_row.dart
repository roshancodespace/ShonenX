import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/presentation/widgets/calendar_airing_card.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

class CalendarDayRow extends StatelessWidget {
  final DateTime date;
  final List<CalendarEntry> entries;
  final bool isLoading;
  final CalendarSource? source;

  const CalendarDayRow({
    super.key,
    required this.date,
    required this.entries,
    this.isLoading = false,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE').format(date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: isToday ? cs.primary : cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d').format(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(radius * 0.4),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: isToday
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(radius * 0.4),
                  ),
                  child: isLoading
                      ? Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        )
                      : Text(
                          entries.isNotEmpty
                              ? '${entries.length} ${entries.length == 1 ? 'Release' : 'Releases'}'
                              : 'No releases',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? cs.primary
                                : cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (isLoading)
            SizedBox(
              height: 212,
              child: Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return CalendarAiringCard(
                      entry: CalendarEntry(
                        id: 'skeleton_$index',
                        mediaId: 'skeleton_$index',
                        title: 'Loading Anime Title Here',
                        englishTitle: 'Loading Anime Title Here',
                        episode: index + 1,
                        totalEpisodes: 12,
                        airingAt: DateTime.now().add(
                          Duration(hours: index * 2),
                        ),
                        genres: const ['Action'],
                        score: 8.5,
                        source: source ?? CalendarSource.anilist,
                      ),
                    );
                  },
                ),
              ),
            )
          else if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'No anime releases scheduled for this day',
                style: TextStyle(
                  fontSize: 12.5,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            SizedBox(
              height: 212,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return CalendarAiringCard(
                    key: ValueKey('${entry.source.name}_${entry.id}'),
                    entry: entry,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
