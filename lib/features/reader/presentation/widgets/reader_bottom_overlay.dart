import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/shared/widgets/app_button_group.dart';
import 'package:shonenx/shared/widgets/app_slider.dart';

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
                  AppActionButtonGroup(
                    outlined: false,
                    height: 42,
                    backgroundColor: widget.appBarBg,
                    foregroundColor: widget.textColor,
                    items: [
                      AppActionItem(
                        icon: Icons.skip_previous_rounded,
                        tooltip: context.l10n.readerPreviousChapter,
                        onTap: widget.hasPrevChapter
                            ? widget.onPrevChapter
                            : () {},
                      ),
                      AppActionItem(
                        icon: Icons.chevron_left_rounded,
                        tooltip: context.l10n.readerPreviousPage,
                        onTap: widget.currentPage > 0
                            ? () => widget.onPageChanged(widget.currentPage - 1)
                            : () {},
                      ),
                    ],
                  ),
                  AppActionButtonGroup(
                    outlined: false,
                    height: 42,
                    backgroundColor: widget.appBarBg,
                    foregroundColor: widget.textColor,
                    items: [
                      AppActionItem(
                        icon: Icons.chevron_right_rounded,
                        tooltip: context.l10n.readerNextPage,
                        onTap: widget.currentPage < maxPage
                            ? () => widget.onPageChanged(widget.currentPage + 1)
                            : () {},
                      ),
                      AppActionItem(
                        icon: Icons.skip_next_rounded,
                        tooltip: context.l10n.readerNextChapter,
                        onTap: widget.hasNextChapter
                            ? widget.onNextChapter
                            : () {},
                      ),
                      AppActionItem(
                        icon: Icons.format_list_bulleted_rounded,
                        tooltip: context.l10n.readerChaptersList,
                        onTap: widget.onChaptersTap,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 28),
                      child: Text(
                        '$displayPage',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _draggingPage != null
                              ? theme.colorScheme.primary
                              : widget.textColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppSlider(
                        value: sliderValue,
                        min: 0,
                        max: maxPage.toDouble(),
                        divisions: widget.totalPages > 1
                            ? widget.totalPages - 1
                            : 1,
                        trackHeight: 6.0,
                        trackGap: 4.0,
                        thumbHeight: 22.0,
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: widget.textColor.withValues(
                          alpha: 0.14,
                        ),
                        thumbColor: theme.colorScheme.primary,
                        showStopIndicator: false,
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
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 28),
                      child: Text(
                        '${widget.totalPages}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.textColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
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
    );
  }
}
