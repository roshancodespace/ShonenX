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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedChapterNum = currentEpisode.number.toString().contains('.0')
        ? currentEpisode.number.toInt()
        : currentEpisode.number;

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: appBarBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: hasPrevChapter ? onPrevChapter : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: textColor,
                    ),
                    TextButton.icon(
                      onPressed: onChaptersTap,
                      icon: Icon(
                        Icons.format_list_bulleted_rounded,
                        color: textColor,
                      ),
                      label: Text(
                        'Chapter $formattedChapterNum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: hasNextChapter ? onNextChapter : null,
                      icon: const Icon(Icons.skip_next_rounded),
                      color: textColor,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        '${currentPage + 1}',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: currentPage.toDouble(),
                            min: 0,
                            max: (totalPages - 1).toDouble(),
                            divisions: totalPages > 1 ? totalPages - 1 : 1,
                            activeColor: theme.colorScheme.primary,
                            inactiveColor: textColor.withValues(alpha: 0.2),
                            onChanged: (value) => onPageChanged(value.toInt()),
                          ),
                        ),
                      ),
                      Text(
                        '$totalPages',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
