import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/reader/providers/reader_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';

import 'chapter_transition.dart';
import 'reader_image.dart';

abstract class _ListItem {}

class _FlattenedPage extends _ListItem {
  final UnifiedEpisode episode;
  final ChapterPage page;
  final int indexInChapter;
  final int totalInChapter;

  _FlattenedPage(
    this.episode,
    this.page,
    this.indexInChapter,
    this.totalInChapter,
  );
}

class _FlattenedTransition extends _ListItem {
  final UnifiedEpisode currentEpisode;
  final UnifiedEpisode adjacentEpisode;
  final bool isNext;

  _FlattenedTransition(this.currentEpisode, this.adjacentEpisode, this.isNext);
}

class _EndTransition extends _ListItem {
  final bool isNext;
  _EndTransition(this.isNext);
}

class ReaderContent extends ConsumerStatefulWidget {
  final AsyncValue<ReaderState> stateAsync;
  final ReaderPrefState prefs;
  final Color textColor;
  final int initialPage;
  final ItemScrollController itemScrollController;
  final ScrollOffsetController? scrollOffsetController;
  final ItemPositionsListener itemPositionsListener;
  final PageController pageController;
  final void Function(int) onTotalPagesUpdated;
  final void Function(int) onPageChanged;
  final void Function(UnifiedEpisode) onChapterChanged;
  final VoidCallback onRetry;
  final String mediaTitle;
  final UnifiedEpisode currentEpisode;
  final String currentChapterName;
  final String? nextChapterName;
  final String? prevChapterName;
  final Future<void> Function() onNextChapter;
  final Future<void> Function() onPrevChapter;

  const ReaderContent({
    super.key,
    required this.stateAsync,
    required this.prefs,
    required this.textColor,
    required this.initialPage,
    required this.itemScrollController,
    this.scrollOffsetController,
    required this.itemPositionsListener,
    required this.pageController,
    required this.onTotalPagesUpdated,
    required this.onPageChanged,
    required this.onChapterChanged,
    required this.onRetry,
    required this.mediaTitle,
    required this.currentEpisode,
    required this.currentChapterName,
    this.nextChapterName,
    this.prevChapterName,
    required this.onNextChapter,
    required this.onPrevChapter,
  });

  @override
  ConsumerState<ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends ConsumerState<ReaderContent> {
  bool _isLoadingNext = false;
  bool _isLoadingPrev = false;
  List<_ListItem> _currentFlatList = [];

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener.itemPositions.addListener(_onWebtoonScroll);
  }

  @override
  void didUpdateWidget(covariant ReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemPositionsListener != widget.itemPositionsListener) {
      oldWidget.itemPositionsListener.itemPositions.removeListener(
        _onWebtoonScroll,
      );
      widget.itemPositionsListener.itemPositions.addListener(_onWebtoonScroll);
    }
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(_onWebtoonScroll);
    super.dispose();
  }

  void _onWebtoonScroll() {
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _currentFlatList.isEmpty) return;
    var current = positions
        .where((p) => p.itemTrailingEdge > 0)
        .reduce((min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min)
        .index;

    if (current >= 0 && current < _currentFlatList.length) {
      final item = _currentFlatList[current];
      if (item is _FlattenedPage) {
        widget.onPageChanged(item.indexInChapter);
        if (item.episode.id != widget.currentEpisode.id) {
          widget.onChapterChanged(item.episode);
        }
      }

      if (current >= _currentFlatList.length - 3) {
        _triggerNext();
      } else if (current <= 2) {
        _triggerPrev();
      }
    }
  }

  void _triggerNext() async {
    if (_isLoadingNext) return;
    setState(() => _isLoadingNext = true);
    await widget.onNextChapter();
    if (mounted) setState(() => _isLoadingNext = false);
  }

  void _triggerPrev() async {
    if (_isLoadingPrev) return;
    setState(() => _isLoadingPrev = true);
    await widget.onPrevChapter();
    if (mounted) setState(() => _isLoadingPrev = false);
  }

  List<_ListItem> _flattenChapters(ReaderState state) {
    final list = <_ListItem>[];
    if (widget.prevChapterName != null) {
      list.add(_EndTransition(false));
    }

    if (state.prevChapterData != null) {
      final chapter = state.prevChapterData!;
      for (var p = 0; p < chapter.pages.length; p++) {
        list.add(
          _FlattenedPage(
            chapter.episode,
            chapter.pages[p],
            p,
            chapter.pages.length,
          ),
        );
      }
      if (state.currentChapterData != null) {
        list.add(
          _FlattenedTransition(
            chapter.episode,
            state.currentChapterData!.episode,
            true,
          ),
        );
      }
    }

    if (state.currentChapterData != null) {
      final chapter = state.currentChapterData!;
      for (var p = 0; p < chapter.pages.length; p++) {
        list.add(
          _FlattenedPage(
            chapter.episode,
            chapter.pages[p],
            p,
            chapter.pages.length,
          ),
        );
      }
    }

    if (state.nextChapterData != null) {
      if (state.currentChapterData != null) {
        list.add(
          _FlattenedTransition(
            state.currentChapterData!.episode,
            state.nextChapterData!.episode,
            true,
          ),
        );
      }
      final chapter = state.nextChapterData!;
      for (var p = 0; p < chapter.pages.length; p++) {
        list.add(
          _FlattenedPage(
            chapter.episode,
            chapter.pages[p],
            p,
            chapter.pages.length,
          ),
        );
      }
    }

    if (widget.nextChapterName != null) {
      list.add(_EndTransition(true));
    }
    return list;
  }

  String _getEpisodeName(UnifiedEpisode ep) {
    return ep.title != null && ep.title!.isNotEmpty
        ? ep.title!
        : 'Chapter ${ep.number}';
  }

  @override
  Widget build(BuildContext context) {
    return widget.stateAsync.when(
      data: (state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return _buildErrorState(state.error!);
        }
        if (state.currentChapterData == null) {
          return Center(
            child: Text(
              'No pages found.',
              style: TextStyle(color: widget.textColor),
            ),
          );
        }

        final flatList = _flattenChapters(state);
        _currentFlatList = flatList;

        int initIndex = 0;
        int currentChapterStartIndex = -1;
        for (var i = 0; i < flatList.length; i++) {
          final item = flatList[i];
          if (item is _FlattenedPage &&
              item.episode.id == widget.currentEpisode.id) {
            currentChapterStartIndex = i;
            break;
          }
        }

        if (currentChapterStartIndex != -1) {
          initIndex =
              currentChapterStartIndex +
              (widget.initialPage >= 0 ? widget.initialPage : 0);
        }
        if (initIndex >= flatList.length)
          initIndex = flatList.length > 0 ? flatList.length - 1 : 0;

        final currentChapterData = state.currentChapterData;
        if (currentChapterData != null) {
          widget.onTotalPagesUpdated(currentChapterData.pages.length);
        }

        final isWebtoon = widget.prefs.direction == ReaderDirection.webtoon;
        final Widget content = isWebtoon
            ? _buildWebtoonView(context, flatList, initIndex)
            : _buildPageView(flatList, initIndex);

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >
                scrollInfo.metrics.maxScrollExtent - 2000) {
              _triggerNext();
            } else if (scrollInfo.metrics.pixels < 2000) {
              _triggerPrev();
            }

            if (scrollInfo is OverscrollNotification) {
              if (scrollInfo.overscroll > 0) {
                _triggerNext();
              } else if (scrollInfo.overscroll < 0) {
                _triggerPrev();
              }
            } else if (scrollInfo is ScrollUpdateNotification) {
              if (scrollInfo.metrics.outOfRange) {
                if (scrollInfo.scrollDelta != null &&
                    scrollInfo.scrollDelta! > 0) {
                  _triggerNext();
                } else if (scrollInfo.scrollDelta != null &&
                    scrollInfo.scrollDelta! < 0) {
                  _triggerPrev();
                }
              }
            }
            return false;
          },
          child: _ZoomableContent(child: content),
        );
      },
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load pages:\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: widget.onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildWebtoonView(
    BuildContext context,
    List<_ListItem> flatList,
    int initIndex,
  ) {
    final isConstrained =
        ResponsiveData.from(context).isDesktop ||
        ResponsiveData.from(context).isTablet;

    return ScrollablePositionedList.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: flatList.length,
      initialScrollIndex: initIndex,
      itemScrollController: widget.itemScrollController,
      scrollOffsetController: widget.scrollOffsetController,
      itemPositionsListener: widget.itemPositionsListener,
      itemBuilder: (context, index) {
        final item = flatList[index];
        if (item is _EndTransition) {
          return ChapterTransition(
            mediaTitle: widget.mediaTitle,
            currentChapterName: widget.currentChapterName,
            nextChapterName: item.isNext
                ? widget.nextChapterName!
                : widget.prevChapterName!,
            isNext: item.isNext,
            isLoading: item.isNext ? _isLoadingNext : _isLoadingPrev,
            onTrigger: item.isNext ? _triggerNext : _triggerPrev,
          );
        } else if (item is _FlattenedTransition) {
          return ChapterTransition(
            mediaTitle: widget.mediaTitle,
            currentChapterName: _getEpisodeName(item.currentEpisode),
            nextChapterName: _getEpisodeName(item.adjacentEpisode),
            isNext: item.isNext,
            isLoading: false,
            onTrigger: () {},
          );
        } else if (item is _FlattenedPage) {
          Widget pageWidget = ReaderImage(
            url: item.page.url,
            headers: item.page.headers ?? const {},
            index: item.indexInChapter,
            scaleType: widget.prefs.scaleType,
            textColor: widget.textColor,
          );

          if (isConstrained) {
            pageWidget = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: pageWidget,
              ),
            );
          }
          return KeyedSubtree(
            key: ValueKey('${item.episode.id}_${item.page.url}'),
            child: pageWidget,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPageView(List<_ListItem> flatList, int initIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pageController.hasClients &&
          widget.pageController.page?.round() != initIndex) {
        // Just let it be for now
      }
    });

    return PageView.builder(
      physics: const BouncingScrollPhysics(),
      controller: widget.pageController,
      reverse: widget.prefs.direction == ReaderDirection.rtl,
      itemCount: flatList.length,
      onPageChanged: (index) {
        if (index >= 0 && index < flatList.length) {
          final item = flatList[index];
          if (item is _FlattenedPage) {
            widget.onPageChanged(item.indexInChapter);
            if (item.episode.id != widget.currentEpisode.id) {
              widget.onChapterChanged(item.episode);
            }
          }

          if (index >= flatList.length - 3) {
            _triggerNext();
          } else if (index <= 2) {
            _triggerPrev();
          }
        }
      },
      itemBuilder: (context, index) {
        final item = flatList[index];
        if (item is _EndTransition) {
          return ChapterTransition(
            mediaTitle: widget.mediaTitle,
            currentChapterName: widget.currentChapterName,
            nextChapterName: item.isNext
                ? widget.nextChapterName!
                : widget.prevChapterName!,
            isNext: item.isNext,
            isLoading: item.isNext ? _isLoadingNext : _isLoadingPrev,
            onTrigger: item.isNext ? _triggerNext : _triggerPrev,
          );
        } else if (item is _FlattenedTransition) {
          return ChapterTransition(
            mediaTitle: widget.mediaTitle,
            currentChapterName: _getEpisodeName(item.currentEpisode),
            nextChapterName: _getEpisodeName(item.adjacentEpisode),
            isNext: item.isNext,
            isLoading: false,
            onTrigger: () {},
          );
        } else if (item is _FlattenedPage) {
          return ReaderImage(
            key: ValueKey('${item.episode.id}_${item.page.url}'),
            url: item.page.url,
            headers: item.page.headers ?? const {},
            index: item.indexInChapter,
            scaleType: widget.prefs.scaleType,
            textColor: widget.textColor,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ZoomableContent extends StatefulWidget {
  final Widget child;

  const _ZoomableContent({required this.child});

  @override
  State<_ZoomableContent> createState() => _ZoomableContentState();
}

class _ZoomableContentState extends State<_ZoomableContent> {
  final TransformationController _controller = TransformationController();
  bool _isZoomed = false;
  int _pointersCount = 0;
  bool _isCtrlPressed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScaleChanged);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  bool _onKeyEvent(KeyEvent event) {
    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (_isCtrlPressed != isCtrl && mounted) {
      setState(() => _isCtrlPressed = isCtrl);
    }
    return false;
  }

  void _onScaleChanged() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _controller.removeListener(_onScaleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      _controller.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      _controller.value = Matrix4.identity()
        ..translateByDouble(-position.dx, -position.dy, 0.0, 1.0)
        ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleEnabled = _pointersCount >= 2 || _isCtrlPressed;

    return Listener(
      onPointerDown: (event) {
        _pointersCount++;
        if (_pointersCount == 2 && mounted) {
          setState(() {});
        }
      },
      onPointerUp: (event) {
        _pointersCount = (_pointersCount - 1).clamp(0, 10);
        if (_pointersCount < 2 && mounted) {
          setState(() {});
        }
      },
      onPointerCancel: (event) {
        _pointersCount = (_pointersCount - 1).clamp(0, 10);
        if (_pointersCount < 2 && mounted) {
          setState(() {});
        }
      },
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final isCtrl =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          if (_isCtrlPressed != isCtrl && mounted) {
            setState(() => _isCtrlPressed = isCtrl);
          }
        }
      },
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: _isZoomed,
          scaleEnabled: scaleEnabled,
          child: widget.child,
        ),
      ),
    );
  }
}
