import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_episode.dart';

class ReaderBottomOverlay extends StatefulWidget {
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
  State<ReaderBottomOverlay> createState() => _ReaderBottomOverlayState();
}

class _ReaderBottomOverlayState extends State<ReaderBottomOverlay> {
  int? _draggingPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayPage = (_draggingPage ?? widget.currentPage) + 1;
    final maxPage = widget.totalPages > 1 ? widget.totalPages - 1 : 1;
    final sliderValue = (_draggingPage ?? widget.currentPage)
        .clamp(0, maxPage)
        .toDouble();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 14,
        left: 16,
        right: 16,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.uiRoundness),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: widget.appBarBg.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(widget.uiRoundness),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Chapter controls & Page Indicator Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Previous Chapter',
                            child: IconButton(
                              onPressed: widget.hasPrevChapter
                                  ? widget.onPrevChapter
                                  : null,
                              icon: const Icon(Icons.skip_previous_rounded),
                              color: widget.textColor,
                              disabledColor: widget.textColor.withValues(
                                alpha: 0.25,
                              ),
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Chapters List',
                            child: IconButton(
                              onPressed: widget.onChaptersTap,
                              icon: const Icon(
                                Icons.format_list_bulleted_rounded,
                              ),
                              color: widget.textColor,
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Next Chapter',
                            child: IconButton(
                              onPressed: widget.hasNextChapter
                                  ? widget.onNextChapter
                                  : null,
                              icon: const Icon(Icons.skip_next_rounded),
                              color: widget.textColor,
                              disabledColor: widget.textColor.withValues(
                                alpha: 0.25,
                              ),
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Current Page Pill/Chip
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _draggingPage != null
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                )
                              : theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.4,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _draggingPage != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                            width: _draggingPage != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: _draggingPage != null
                                  ? theme.colorScheme.primary
                                  : widget.textColor.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Page $displayPage / ${widget.totalPages}',
                              style: TextStyle(
                                color: _draggingPage != null
                                    ? theme.colorScheme.primary
                                    : widget.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Bottom Row: Page Step Buttons and Precision Slider
                  Row(
                    children: [
                      Tooltip(
                        message: 'Previous Page',
                        child: IconButton(
                          onPressed: widget.currentPage > 0
                              ? () =>
                                    widget.onPageChanged(widget.currentPage - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: widget.textColor,
                          disabledColor: widget.textColor.withValues(
                            alpha: 0.25,
                          ),
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.5,
                              // pressedThumbRadius: 9,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            activeTrackColor: theme.colorScheme.primary,
                            inactiveTrackColor: widget.textColor.withValues(
                              alpha: 0.15,
                            ),
                            thumbColor: theme.colorScheme.primary,
                            overlayColor: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Slider(
                            value: sliderValue,
                            min: 0,
                            max: maxPage.toDouble(),
                            divisions: widget.totalPages > 1
                                ? widget.totalPages - 1
                                : 1,
                            onChanged: (value) {
                              setState(() => _draggingPage = value.toInt());
                              widget.onPageChanged(value.toInt());
                            },
                            onChangeEnd: (value) {
                              setState(() => _draggingPage = null);
                              widget.onPageChanged(value.toInt());
                            },
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Next Page',
                        child: IconButton(
                          onPressed: widget.currentPage < maxPage
                              ? () =>
                                    widget.onPageChanged(widget.currentPage + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: widget.textColor,
                          disabledColor: widget.textColor.withValues(
                            alpha: 0.25,
                          ),
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
