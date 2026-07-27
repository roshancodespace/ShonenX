import 'package:flutter/material.dart';

class ReaderBottomOverlay extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final bool hasPrevChapter;
  final bool hasNextChapter;
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
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Prev chapter + prev page
                  _buildPillContainer(
                    children: [
                      _navButton(
                        icon: Icons.skip_previous_rounded,
                        size: 20,
                        onPressed: widget.hasPrevChapter
                            ? widget.onPrevChapter
                            : null,
                        tooltip: 'Previous Chapter',
                      ),
                      _navButton(
                        icon: Icons.chevron_left_rounded,
                        size: 22,
                        onPressed: widget.currentPage > 0
                            ? () => widget.onPageChanged(widget.currentPage - 1)
                            : null,
                        tooltip: 'Previous Page',
                      ),
                    ],
                  ),
                  _buildPillContainer(
                    children: [
                      _navButton(
                        icon: Icons.chevron_right_rounded,
                        size: 22,
                        onPressed: widget.currentPage < maxPage
                            ? () => widget.onPageChanged(widget.currentPage + 1)
                            : null,
                        tooltip: 'Next Page',
                      ),
                      _navButton(
                        icon: Icons.skip_next_rounded,
                        size: 20,
                        onPressed: widget.hasNextChapter
                            ? widget.onNextChapter
                            : null,
                        tooltip: 'Next Chapter',
                      ),
                      _navButton(
                        icon: Icons.format_list_bulleted_rounded,
                        size: 18,
                        onPressed: widget.onChaptersTap,
                        tooltip: 'Chapters List',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _buildPillContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  Text(
                    '$displayPage',
                    style: TextStyle(
                      color: _draggingPage != null
                          ? theme.colorScheme.primary
                          : widget.textColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: widget.textColor.withValues(
                          alpha: 0.12,
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
                  const SizedBox(width: 8),
                  Text(
                    '${widget.totalPages}',
                    style: TextStyle(
                      color: widget.textColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillContainer({
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 4,
    ),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: widget.appBarBg,
        borderRadius: BorderRadius.circular(widget.uiRoundness),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _navButton({
    required IconData icon,
    required double size,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      style: IconButton.styleFrom(
        minimumSize: const Size(38, 38),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            (widget.uiRoundness - 4).clamp(0.0, widget.uiRoundness),
          ),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      color: widget.textColor,
      disabledColor: widget.textColor.withValues(alpha: 0.2),
      tooltip: tooltip,
    );
  }
}
