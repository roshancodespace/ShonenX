import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/features/calendar/providers/calendar_prefs_provider.dart';
import 'package:shonenx/features/calendar/providers/calendar_schedule_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_icon_button.dart';

class CalendarWeekHeader extends ConsumerWidget {
  const CalendarWeekHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final prefs = ref.watch(calendarPrefsProvider);
    final prefsNotifier = ref.read(calendarPrefsProvider.notifier);
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;
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

    final localeStr = Localizations.localeOf(context).toString();
    final startStr = DateFormat('MMM d', localeStr).format(weekStart);
    final endStr = weekStart.month == weekEnd.month
        ? DateFormat('d, yyyy', localeStr).format(weekEnd)
        : DateFormat('MMM d, yyyy', localeStr).format(weekEnd);

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
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isClassic
                            ? cs.primary.withValues(alpha: 0.12)
                            : cs.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          isClassic ? 4 : 999,
                        ),
                      ),
                      child: Text(
                        'CURRENT WEEK',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isClassic
                              ? cs.primary
                              : cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    icon: const Icon(CupertinoIcons.chevron_back),
                    tooltip: 'Previous Week',
                    size: 34,
                    radius: isClassic ? 8.0 : 999.0,
                    backgroundColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    onPressed: () {
                      ref
                          .read(selectedWeekStartProvider.notifier)
                          .previousWeek();
                    },
                  ),
                  const SizedBox(width: 6),
                  AppIconButton(
                    icon: const Icon(CupertinoIcons.chevron_forward),
                    tooltip: 'Next Week',
                    size: 34,
                    radius: isClassic ? 8.0 : 999.0,
                    backgroundColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.4,
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
