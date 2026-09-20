import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/providers/calendar_schedule_provider.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class CalendarAiringCard extends ConsumerWidget {
  final CalendarEntry entry;

  const CalendarAiringCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    final libraryIds = ref.watch(calendarLibraryIdsProvider).value ?? {};
    final isInLibrary =
        libraryIds.contains(entry.mediaId.toLowerCase()) ||
        libraryIds.contains(entry.title.toLowerCase().trim()) ||
        (entry.englishTitle != null &&
            libraryIds.contains(entry.englishTitle!.toLowerCase().trim())) ||
        (entry.romajiTitle != null &&
            libraryIds.contains(entry.romajiTitle!.toLowerCase().trim()));

    final isAired = entry.isAired;
    final timeUntil = entry.timeUntilAiring;

    String exactTimeStr = '';
    if (entry.airingAt != null) {
      exactTimeStr = DateFormat('HH:mm').format(entry.airingAt!);
    } else if (entry.broadcastTime != null) {
      exactTimeStr = entry.broadcastTime!;
    }

    String countdownStr = '';
    if (timeUntil != null) {
      if (timeUntil.inDays > 0) {
        countdownStr = '${timeUntil.inDays}d';
      } else if (timeUntil.inHours > 0) {
        countdownStr = '${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m';
      } else if (timeUntil.inMinutes > 0) {
        countdownStr = '${timeUntil.inMinutes}m';
      } else {
        countdownStr = 'Now';
      }
    }

    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return MediaCard(
      forceWideMode: false,
      media: entry.toUnifiedMedia(),
      style: style,
      tag: 'calendar_${entry.id}',
      onTap: () {
        context.pushDetails(
          media: entry.toUnifiedMedia(),
          mediaType: MediaType.ANIME,
        );
      },
      subtitle: entry.episode != null ? 'Episode ${entry.episode}' : null,
      topLeftBadge: isInLibrary
          ? Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                size: 10,
                color: Colors.white,
              ),
            )
          : null,
      bottomLeftBadge: exactTimeStr.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(radius * 0.4),
              ),
              child: Text(
                exactTimeStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isAired ? Colors.white70 : Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            )
          : const SizedBox.shrink(),
      bottomRightBadge: countdownStr.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(radius * 0.4),
              ),
              child: Text(
                countdownStr,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: cs.onPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
