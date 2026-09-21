import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/custom_subtitle_provider.dart';
import 'package:shonenx/features/player/domain/subtitle_prefs.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';

class CustomSubtitleOverlay extends ConsumerWidget {
  const CustomSubtitleOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(subtitlePrefsProvider);
    if (!prefs.useCustomSubtitle) return const SizedBox.shrink();

    final cuesAsync = ref.watch(customSubtitleProvider);

    return cuesAsync.when(
      data: (cues) {
        if (cues.isEmpty) return const SizedBox.shrink();

        // Listen to engine position changes
        final position = ref.watch(
          videoEngineStateProvider.select((s) => s.position),
        );

        // Find all active overlapping cues
        final activeCues = _findActiveCues(cues, position);

        if (activeCues.isEmpty) return const SizedBox.shrink();

        final screenWidth = MediaQuery.sizeOf(context).width;
        final responsiveFontSize = getResponsiveSubtitleSize(
          screenWidth,
          prefs.fontSize,
        );

        final Map<Alignment, List<SubtitleCue>> groupedCues = {};
        for (final cue in activeCues) {
          groupedCues.putIfAbsent(cue.alignment, () => []).add(cue);
        }

        return Positioned.fill(
          child: IgnorePointer(
            child: SafeArea(
              child: Stack(
                children: groupedCues.entries.map((entry) {
                  final alignment = entry.key;
                  final cuesForAlignment = entry.value;

                  return Align(
                    alignment: alignment,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: alignment.y == 1.0 ? prefs.bottomPadding : 0,
                        top: alignment.y == -1.0 ? prefs.bottomPadding : 0,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: cuesForAlignment
                            .expand(
                              (
                                cue,
                              ) => SubtitleParser.cleanSubtitleText(cue.text)
                                  .split('\n')
                                  .map((l) => l.replaceAll('\r', ''))
                                  .where((l) => l.trim().isNotEmpty)
                                  .map(
                                    (line) => Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: prefs.padding * 1.5,
                                        vertical: prefs.padding * 0.5,
                                      ),
                                      decoration:
                                          prefs.backgroundColor != 0x00000000
                                          ? BoxDecoration(
                                              color: prefs.bg,
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            )
                                          : null,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (getSubtitleStrokeStyle(
                                                prefs,
                                                responsiveFontSize,
                                              ) !=
                                              null)
                                            Text(
                                              line,
                                              textAlign: TextAlign.center,
                                              style: getSubtitleStrokeStyle(
                                                prefs,
                                                responsiveFontSize,
                                              ),
                                            ),
                                          Text(
                                            line,
                                            textAlign: TextAlign.center,
                                            style: getSubtitleTextStyle(
                                              prefs,
                                              responsiveFontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<SubtitleCue> _findActiveCues(List<SubtitleCue> cues, Duration position) {
    if (cues.isEmpty) return [];

    // Binary search for the first cue that starts AFTER the current position
    int low = 0;
    int high = cues.length - 1;
    int insertIndex = cues.length;

    while (low <= high) {
      int mid = low + ((high - low) >> 1);
      if (cues[mid].start > position) {
        insertIndex = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    // Iterate backwards to find all overlapping cues
    final List<SubtitleCue> activeCues = [];
    for (int i = insertIndex - 1; i >= 0; i--) {
      final cue = cues[i];
      if (cue.end >= position) {
        activeCues.add(cue);
      }
      // Stop searching if the cue started more than 60 seconds ago
      if (position.inSeconds - cue.start.inSeconds > 60) {
        break;
      }
    }

    return activeCues.reversed.toList();
  }
}
