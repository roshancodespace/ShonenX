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

        // Find the active cue using binary search
        final activeCue = _findActiveCue(cues, position);

        if (activeCue == null) return const SizedBox.shrink();

        final screenWidth = MediaQuery.sizeOf(context).width;
        final responsiveFontSize = getResponsiveSubtitleSize(
          screenWidth,
          prefs.fontSize,
        );

        return Positioned(
          bottom: prefs.bottomPadding, // Configurable bottom padding
          left: 0,
          right: 0,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: SubtitleParser.cleanSubtitleText(activeCue.text)
                      .split('\n')
                      .map((l) => l.replaceAll('\r', ''))
                      .where((l) => l.trim().isNotEmpty)
                      .map(
                        (line) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: prefs.padding * 1.5,
                            vertical: prefs.padding * 0.5,
                          ),
                          decoration: prefs.backgroundColor != 0x00000000
                              ? BoxDecoration(
                                  color: prefs.bg,
                                  borderRadius: BorderRadius.circular(4.0),
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
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  SubtitleCue? _findActiveCue(List<SubtitleCue> cues, Duration position) {
    if (cues.isEmpty) return null;

    int low = 0;
    int high = cues.length - 1;

    while (low <= high) {
      // Bitwise shift is slightly faster than division by 2
      int mid = low + ((high - low) >> 1);
      final cue = cues[mid];

      if (position >= cue.start && position <= cue.end) {
        return cue; // Target found
      } else if (position < cue.start) {
        high = mid - 1; // Target is in the earlier half
      } else {
        low = mid + 1; // Target is in the later half
      }
    }

    return null; // No active subtitle at this position
  }
}
