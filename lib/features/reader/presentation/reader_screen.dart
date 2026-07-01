import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/reader/providers/reader_provider.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

import 'widgets/chapters_bottom_sheet.dart';
import 'widgets/reader_app_bar.dart';
import 'widgets/reader_bottom_overlay.dart';
import 'widgets/reader_content.dart';
import 'widgets/reader_theme_info.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final ReaderModeOnline mode;

  const ReaderScreen({super.key, required this.mode});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showOverlay = false;
  int _currentPage = 0;
  int _totalPages = 0;

  Offset? _pointerDownPos;

  late final FocusNode _focusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late final PageController _pageController;
  final TransformationController _transformationController =
      TransformationController();
  late final MatchArgs _matchArgs;

  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _enableImmersiveMode();
    _focusNode.requestFocus();
    _itemPositionsListener.itemPositions.addListener(_onWebtoonScroll);
    _matchArgs = MatchArgs(
      mediaTitle: widget.mode.media.title.availableTitle,
      type: widget.mode.media.type,
    );
    _currentPage = widget.mode.startPosition > 0
        ? widget.mode.startPosition - 1
        : 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onWebtoonScroll);
    _pageController.dispose();
    _transformationController.dispose();
    _disableImmersiveMode();
    super.dispose();
  }

  void _enableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _disableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    _showOverlay ? _disableImmersiveMode() : _enableImmersiveMode();
  }

  void _onWebtoonScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _totalPages == 0) return;

    var current = positions
        .where((p) => p.itemTrailingEdge > 0)
        .reduce((min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min)
        .index;

    for (final p in positions) {
      if (p.index == _totalPages - 1 && p.itemTrailingEdge <= 1.01) {
        current = _totalPages - 1;
        break;
      }
    }

    if (_currentPage != current) {
      setState(() => _currentPage = current);
      _saveHistory();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _saveHistory();
  }

  void _saveHistory() {
    if (_totalPages == 0) return;

    final savedPageNumber = _currentPage + 1;

    final entry = ReadHistoryEntry()
      ..chapterNumber = widget.mode.episode.number
      ..mangaId = widget.mode.media.id
      ..mangaTitle = widget.mode.media.title.availableTitle
      ..cover = widget.mode.media.cover
      ..banner = widget.mode.media.banner
      ..positionPage = savedPageNumber
      ..totalPages = _totalPages
      ..lastUpdated = DateTime.now();

    ref.read(readHistoryRepositoryProvider).saveProgress(entry);
    ref
        .read(syncEngineProvider)
        .processReading(
          media: widget.mode.media,
          chapterNumber: widget.mode.episode.number,
          positionPage: savedPageNumber,
          totalPages: _totalPages,
        );
  }

  void _navigateToEpisode(UnifiedEpisode ep, SourceInfo sourceInfo) {
    context.replace(
      '/reader',
      extra: ReaderModeOnline(
        media: widget.mode.media,
        episode: ep,
        sourceInfo: sourceInfo,
      ),
    );
  }

  void _skipToChapter(EpisodesListState? episodesState, {required bool next}) {
    if (episodesState == null) return;

    final currentNum = widget.mode.episode.number;
    final adjacentEps = episodesState.episodes
        .where((e) => next ? e.number > currentNum : e.number < currentNum)
        .toList();

    if (adjacentEps.isEmpty) return;

    final targetChapterNum = next
        ? adjacentEps.first.number
        : adjacentEps.last.number;
    final candidates = adjacentEps
        .where((e) => e.number == targetChapterNum)
        .toList();

    final prefScanlator = ref.read(
      preferredScanlatorProvider(widget.mode.media.id),
    );
    final target = candidates.firstWhere(
      (e) => e.scanlator == prefScanlator,
      orElse: () => candidates.first,
    );

    if (target.id != widget.mode.episode.id) {
      _navigateToEpisode(target, episodesState.source);
    }
  }

  void _showChaptersSheet(EpisodesListState? episodesState) {
    if (episodesState == null) return;

    AppBottomSheet.show(
      context: context,
      title: 'Chapters',
      child: ChaptersBottomSheet(
        matchArgs: _matchArgs,
        currentEpisode: widget.mode.episode,
        mediaId: widget.mode.media.id,
        sourceInfo: episodesState.source,
        onEpisodeSelected: (ep) => _navigateToEpisode(ep, episodesState.source),
      ),
    );
  }

  void _updateTotalPagesIfNeeded(int count) {
    if (_totalPages != count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _totalPages = count);
          _saveHistory();
        }
      });
    }
  }

  bool _hasChapter(EpisodesListState? episodesState, {required bool next}) {
    if (episodesState == null) return false;
    final currentNum = widget.mode.episode.number;
    return episodesState.episodes.any(
      (e) => next ? e.number > currentNum : e.number < currentNum,
    );
  }

  void _jumpToPage(int newPage, ReaderDirection direction) {
    if (direction == ReaderDirection.webtoon) {
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: newPage);
      }
    } else {
      _pageController.jumpToPage(newPage);
    }
    setState(() => _currentPage = newPage);
  }

  ReaderThemeInfo _getThemeInfo(ReaderBackgroundColor bgColorPref) {
    switch (bgColorPref) {
      case ReaderBackgroundColor.white:
        return ReaderThemeInfo(
          bgColor: Colors.white,
          appBarBg: Colors.white.withValues(alpha: 0.9),
          textColor: Colors.black,
        );
      case ReaderBackgroundColor.darkGrey:
        return ReaderThemeInfo(
          bgColor: Colors.grey[900]!,
          appBarBg: Colors.grey[900]!.withValues(alpha: 0.9),
          textColor: Colors.white,
        );
      case ReaderBackgroundColor.black:
        return ReaderThemeInfo(
          bgColor: Colors.black,
          appBarBg: Colors.black.withValues(alpha: 0.8),
          textColor: Colors.white,
        );
    }
  }

  void _toggleZoom(TapDownDetails details) {
    final tapPosition = details.localPosition;
    final targetScale = (_currentScale < 2.0) ? 2.0 : 1.0;
    _zoomAtPoint(tapPosition, targetScale);
  }

  void _zoomOnScroll(double scrollDelta, Offset pointerPosition) {
    final zoomFactor = (scrollDelta < 0) ? 1.1 : 0.9;
    final newScale = (_currentScale * zoomFactor).clamp(1.0, 4.0);
    _zoomAtPoint(pointerPosition, newScale);
  }

  void _zoomAtPoint(Offset focalPoint, double targetScale) {
    _currentScale = targetScale;
    final scenePoint = _transformationController.toScene(focalPoint);
    _transformationController.value = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(_currentScale)
      ..translate(-scenePoint.dx, -scenePoint.dy);
  }

  @override
  Widget build(BuildContext context) {
    final readerStateAsync = ref.watch(readerProvider(widget.mode));
    final readerPrefs = ref.watch(readerPrefsProvider);
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );
    final episodesState = ref.watch(episodesListProvider(_matchArgs)).value;

    final themeInfo = _getThemeInfo(readerPrefs.backgroundColor);

    return Scaffold(
      backgroundColor: themeInfo.bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            removeLeft: true,
            removeRight: true,
            child: KeyboardListener(
              focusNode: _focusNode,
              child: Listener(
                onPointerDown: (event) => _pointerDownPos = event.position,
                onPointerUp: (event) {
                  if (_pointerDownPos != null) {
                    final distance =
                        (event.position - _pointerDownPos!).distance;
                    if (distance < 10) {
                      _toggleOverlay();
                    }
                  }
                },
                child: ReaderContent(
                  stateAsync: readerStateAsync,
                  prefs: readerPrefs,
                  textColor: themeInfo.textColor,
                  initialPage: _currentPage,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  pageController: _pageController,
                  transformationController: _transformationController,
                  onTotalPagesUpdated: _updateTotalPagesIfNeeded,
                  onPageChanged: _onPageChanged,
                  onZoomOnScroll: _zoomOnScroll,
                  onToggleZoom: _toggleZoom,
                  onRetry: () =>
                      ref.read(readerProvider(widget.mode).notifier).retry(),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            top: _showOverlay ? 0 : -100,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showOverlay,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showOverlay ? 1.0 : 0.0,
                child: ReaderAppBar(
                  mediaTitle: widget.mode.media.title.availableTitle,
                  episodeNumber: widget.mode.episode.number,
                  themeInfo: themeInfo,
                ),
              ),
            ),
          ),
          if (_totalPages > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              bottom: _showOverlay ? 0 : -150,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _showOverlay ? 1.0 : 0.0,
                  child: ReaderBottomOverlay(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    hasPrevChapter: _hasChapter(episodesState, next: false),
                    hasNextChapter: _hasChapter(episodesState, next: true),
                    currentEpisode: widget.mode.episode,
                    appBarBg: themeInfo.appBarBg,
                    textColor: themeInfo.textColor,
                    uiRoundness: uiRoundness,
                    onPrevChapter: () =>
                        _skipToChapter(episodesState, next: false),
                    onNextChapter: () =>
                        _skipToChapter(episodesState, next: true),
                    onChaptersTap: () => _showChaptersSheet(episodesState),
                    onPageChanged: (newPage) =>
                        _jumpToPage(newPage, readerPrefs.direction),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
