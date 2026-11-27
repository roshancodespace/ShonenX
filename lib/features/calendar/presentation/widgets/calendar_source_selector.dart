import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/features/calendar/providers/calendar_prefs_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/selection_card_group.dart';

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
    final sources = CalendarSource.values;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectionCardGroup(
            title: 'Schedule Source',
            subtitle:
                'Select the provider for weekly airing schedules and release timetables.',
            children: sources.asMap().entries.map((entry) {
              final idx = entry.key;
              final source = entry.value;
              final isLast = idx == sources.length - 1;
              final isSelected = prefs.source == source;

              return SelectionCardTile(
                leading: source.trackerType.getIconWidget(
                  size: 24,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                title: source.displayName,
                subtitle: source.subtitle,
                isSelected: isSelected,
                showDivider: !isLast,
                onTap: () {
                  ref.read(calendarPrefsProvider.notifier).setSource(source);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Done',
            isExpanded: true,
            onPressed: context.pop,
          ),
        ],
      ),
    );
  }
}
