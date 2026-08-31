import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/providers/calendar_prefs_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

extension CalendarSourceTrackerX on CalendarSource {
  TrackerType get trackerType => switch (this) {
    CalendarSource.anilist => TrackerType.anilist,
    CalendarSource.mal => TrackerType.myanimelist,
    CalendarSource.simkl => TrackerType.simkl,
    CalendarSource.kitsu => TrackerType.kitsu,
  };
}

class CalendarSourceSelectorSheet extends ConsumerWidget {
  const CalendarSourceSelectorSheet({super.key});

  static void show(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Calendar Source',
      child: const CalendarSourceSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(calendarPrefsProvider);
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Select a provider for weekly airing schedules and release timetables.',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: Column(
            children: CalendarSource.values.asMap().entries.map((entry) {
              final index = entry.key;
              final source = entry.value;
              final isSelected = prefs.source == source;
              final isLast = index == CalendarSource.values.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      ref
                          .read(calendarPrefsProvider.notifier)
                          .setSource(source);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerHighest.withValues(
                                      alpha: 0.6,
                                    ),
                              borderRadius: BorderRadius.circular(radius * 0.6),
                            ),
                            child: source.trackerType.getIconWidget(
                              size: 22,
                              color: isSelected ? cs.primary : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source.displayName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 14.5,
                                    color: isSelected
                                        ? cs.primary
                                        : cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  source.subtitle,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? cs.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary
                                    : cs.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
