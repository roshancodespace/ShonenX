import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_entry.dart';
import 'package:shonenx/features/calendar/providers/calendar_schedule_provider.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';

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

    return SizedBox(
      width: 122,
      child: InkWell(
        onTap: () {
          context.pushDetails(
            media: entry.toUnifiedMedia(),
            mediaType: MediaType.ANIME,
          );
        },
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius * 0.8),
                child: SizedBox(
                  width: 122,
                  height: 162,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (entry.coverUrl != null && entry.coverUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: entry.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: cs.surfaceContainerHighest.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest.withValues(
                              alpha: 0.4,
                            ),
                            child: const Icon(Icons.movie_outlined, size: 24),
                          ),
                        )
                      else
                        Container(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          child: const Icon(Icons.movie_outlined, size: 24),
                        ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.4, 0.7, 1.0],
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        right: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isInLibrary)
                              Container(
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
                            else if (entry.format != null &&
                                entry.format!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(
                                    radius * 0.3,
                                  ),
                                ),
                                child: Text(
                                  entry.format!,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            if (entry.score != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(
                                    radius * 0.3,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 10.5,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 1.5),
                                    Text(
                                      entry.score!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (exactTimeStr.isNotEmpty)
                              Text(
                                exactTimeStr,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: isAired
                                      ? Colors.white60
                                      : Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            if (countdownStr.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(
                                    radius * 0.3,
                                  ),
                                ),
                                child: Text(
                                  countdownStr,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: cs.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              if (entry.episode != null)
                Text(
                  'Episode ${entry.episode}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              Text(
                entry.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.1,
                  color: isAired
                      ? cs.onSurface.withValues(alpha: 0.75)
                      : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
