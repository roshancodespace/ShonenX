import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_episode.dart';

class ReaderBottomOverlay extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasPrevChapter;
  final bool hasNextChapter;
  final UnifiedEpisode currentEpisode;
  final Color appBarBg;
  final Color textColor;
  final void Function() onPrevChapter;
  final void Function() onNextChapter;
  final void Function() onChaptersTap;
  final void Function(int) onPageChanged;
  final double uiRoundness;

  const ReaderBottomOverlay({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasPrevChapter,
    required this.hasNextChapter,
    required this.currentEpisode,
    required this.appBarBg,
    required this.textColor,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onChaptersTap,
    required this.onPageChanged,
    required this.uiRoundness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 320,
          ), // More compact width
          decoration: BoxDecoration(
            color: appBarBg,
            borderRadius: BorderRadius.circular(uiRoundness),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${currentPage + 1}',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: textColor.withValues(alpha: 0.15),
                        thumbColor: theme.colorScheme.primary,
                      ),
                      child: Slider(
                        value: currentPage.toDouble(),
                        min: 0,
                        max: (totalPages > 1 ? totalPages - 1 : 1).toDouble(),
                        divisions: totalPages > 1 ? totalPages - 1 : 1,
                        onChanged: (value) => onPageChanged(value.toInt()),
                      ),
                    ),
                  ),
                  Text(
                    '$totalPages',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: hasPrevChapter ? onPrevChapter : null,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: textColor,
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: onChaptersTap,
                    icon: const Icon(Icons.format_list_bulleted_rounded),
                    color: textColor,
                    iconSize: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: hasNextChapter ? onNextChapter : null,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: textColor,
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
