import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/reader/providers/reader_provider.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
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
  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;

  Offset? _pointerDownPos;

  late final FocusNode _focusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ScrollOffsetController _scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late final PageController _pageController;
  late final MatchArgs _matchArgs;

  @override
  void initState() {
    super.initState();
    _enableImmersiveMode();
    _focusNode.requestFocus();
    HardwareKeyboard.instance.addHandler(_onScreenKeyEvent);
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
    _autoScrollTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onScreenKeyEvent);
    _focusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onWebtoonScroll);
    _pageController.dispose();
    _disableImmersiveMode();
    super.dispose();
  }

  bool _onScreenKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final prefs = ref.read(readerPrefsProvider);
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      if (_currentPage > 0) _jumpToPage(_currentPage - 1, prefs.direction);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.space) {
      if (_currentPage < _totalPages - 1) {
        _jumpToPage(_currentPage + 1, prefs.direction);
      } else {
        final episodesState = ref.read(episodesListProvider(_matchArgs)).value;
        _skipToChapter(episodesState, next: true);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.home) {
      _jumpToPage(0, prefs.direction);
      return true;
    }
    if (key == LogicalKeyboardKey.end && _totalPages > 0) {
      _jumpToPage(_totalPages - 1, prefs.direction);
      return true;
    }
    if (key == LogicalKeyboardKey.keyF || key == LogicalKeyboardKey.f11) {
      _toggleOverlay();
      return true;
    }
    if (key == LogicalKeyboardKey.keyK) {
      _toggleAutoScroll();
      return true;
    }
    if (key == LogicalKeyboardKey.keyN) {
      final episodesState = ref.read(episodesListProvider(_matchArgs)).value;
      _skipToChapter(episodesState, next: true);
      return true;
    }
    if (key == LogicalKeyboardKey.keyP) {
      final episodesState = ref.read(episodesListProvider(_matchArgs)).value;
      _skipToChapter(episodesState, next: false);
      return true;
    }
    return false;
  }

  void _toggleAutoScroll() {
    final prefs = ref.read(readerPrefsProvider);
    if (prefs.direction != ReaderDirection.webtoon) return;

    if (_isAutoScrolling) {
      _autoScrollTimer?.cancel();
      setState(() => _isAutoScrolling = false);
    } else {
      setState(() => _isAutoScrolling = true);
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final prefs = ref.read(readerPrefsProvider);
    final speed = prefs.autoScrollSpeed;

    if (prefs.direction == ReaderDirection.webtoon) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (
        timer,
      ) {
        if (!mounted ||
            !_isAutoScrolling ||
            !_itemScrollController.isAttached) {
          timer.cancel();
          return;
        }
        final delta = speed * 4.0;
        try {
          _scrollOffsetController.animateScroll(
            offset: delta,
            duration: const Duration(milliseconds: 30),
          );
        } catch (_) {}
      });
    } else {
      final intervalSeconds = (6.0 / speed).clamp(1.5, 10.0).toInt();
      _autoScrollTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
        timer,
      ) {
        if (!mounted || !_isAutoScrolling) {
          timer.cancel();
          return;
        }
        if (_currentPage < _totalPages - 1) {
          _jumpToPage(_currentPage + 1, prefs.direction);
        } else {
          _toggleAutoScroll();
          final episodesState = ref
              .read(episodesListProvider(_matchArgs))
              .value;
          _skipToChapter(episodesState, next: true);
        }
      });
    }
  }

  void _changeAutoScrollSpeed() {
    final prefsNotifier = ref.read(readerPrefsProvider.notifier);
    final current = ref.read(readerPrefsProvider).autoScrollSpeed;
    final nextSpeed = current == 1.0
        ? 1.5
        : current == 1.5
        ? 2.0
        : current == 2.0
        ? 3.0
        : 1.0;
    prefsNotifier.updateAutoScrollSpeed(nextSpeed);
    if (_isAutoScrolling) {
      _startAutoScroll();
    }
  }

  void _enableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    try {
      if (ref.read(readerPrefsProvider).keepScreenOn) {
        WakelockPlus.enable();
      }
    } catch (_) {}
  }

  void _disableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    try {
      WakelockPlus.disable();
    } catch (_) {}
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
      ..sourceId = widget.mode.sourceInfo.id
      ..sourceName = widget.mode.sourceInfo.name
      ..providerId = widget.mode.media.providerId != widget.mode.media.id
          ? widget.mode.media.providerId
          : null
      ..lastUpdated = DateTime.now();

    ref.read(readHistoryRepositoryProvider).saveProgress(entry);

    try {
      final mediaTitle = widget.mode.media.title.availableTitle;
      if (mediaTitle.isNotEmpty) {
        ref
            .read(
              mediaPreferenceProvider(
                MatchArgs(mediaTitle: mediaTitle, type: widget.mode.media.type),
              ).notifier,
            )
            .saveWatchPreference(
              sourceInfo: widget.mode.sourceInfo,
              mediaId: widget.mode.media.providerId ?? widget.mode.media.id,
              mediaTitle: mediaTitle,
            );
      }
    } catch (_) {}
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
    _saveHistory();
  }

  ReaderThemeInfo _getThemeInfo(ReaderBackgroundColor bgColorPref) {
    switch (bgColorPref) {
      case ReaderBackgroundColor.white:
        return const ReaderThemeInfo(
          bgColor: Colors.white,
          appBarBg: Color(0xFFF4F4F5),
          textColor: Color(0xFF18181B),
        );
      case ReaderBackgroundColor.darkGrey:
        return const ReaderThemeInfo(
          bgColor: Color(0xFF18181B),
          appBarBg: Color(0xFF27272A),
          textColor: Color(0xFFFAFAFA),
        );
      case ReaderBackgroundColor.black:
        return const ReaderThemeInfo(
          bgColor: Colors.black,
          appBarBg: Color(0xFF141414),
          textColor: Color(0xFFF4F4F5),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerStateAsync = ref.watch(readerProvider(widget.mode));
    final readerPrefs = ref.watch(readerPrefsProvider);
    final episodesState = ref.watch(episodesListProvider(_matchArgs)).value;

    if (_isAutoScrolling && readerPrefs.direction != ReaderDirection.webtoon) {
      _autoScrollTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isAutoScrolling) {
          setState(() => _isAutoScrolling = false);
        }
      });
    }

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
                      final width = MediaQuery.of(context).size.width;
                      if (readerPrefs.tapToTurnPage && !_showOverlay) {
                        if (event.position.dx < width * 0.3) {
                          if (_currentPage > 0) {
                            _jumpToPage(
                              _currentPage - 1,
                              readerPrefs.direction,
                            );
                          } else {
                            _skipToChapter(episodesState, next: false);
                          }
                        } else if (event.position.dx > width * 0.7) {
                          if (_currentPage < _totalPages - 1) {
                            _jumpToPage(
                              _currentPage + 1,
                              readerPrefs.direction,
                            );
                          } else {
                            _skipToChapter(episodesState, next: true);
                          }
                        } else {
                          _toggleOverlay();
                        }
                      } else {
                        _toggleOverlay();
                      }
                    }
                  }
                },
                child: ReaderContent(
                  stateAsync: readerStateAsync,
                  prefs: readerPrefs,
                  textColor: themeInfo.textColor,
                  initialPage: _currentPage,
                  itemScrollController: _itemScrollController,
                  scrollOffsetController: _scrollOffsetController,
                  itemPositionsListener: _itemPositionsListener,
                  pageController: _pageController,
                  onTotalPagesUpdated: _updateTotalPagesIfNeeded,
                  onPageChanged: _onPageChanged,
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
                  uiRoundness: GlobalUI.uiRoundness,
                ),
              ),
            ),
          ),
          if (_totalPages > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              bottom: _showOverlay ? 0 : -160,
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
                    totalChaptersCount: episodesState != null
                        ? episodesState.episodes
                              .map((e) => e.number)
                              .toSet()
                              .length
                        : 0,
                    currentEpisode: widget.mode.episode,
                    appBarBg: themeInfo.appBarBg,
                    textColor: themeInfo.textColor,
                    uiRoundness: GlobalUI.uiRoundness,
                    isAutoScrolling:
                        _isAutoScrolling &&
                        readerPrefs.direction == ReaderDirection.webtoon,
                    autoScrollSpeed: readerPrefs.autoScrollSpeed,
                    onToggleAutoScroll:
                        readerPrefs.direction == ReaderDirection.webtoon
                        ? _toggleAutoScroll
                        : null,
                    onChangeAutoScrollSpeed:
                        readerPrefs.direction == ReaderDirection.webtoon
                        ? _changeAutoScrollSpeed
                        : null,
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
          if (!_showOverlay && readerPrefs.showMiniStatus && _totalPages > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              bottom: 16,
              right: 16,
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeInfo.appBarBg.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAutoScrolling &&
                          readerPrefs.direction == ReaderDirection.webtoon) ...[
                        Icon(
                          Icons.play_circle_filled_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        'Ch. ${widget.mode.episode.number} • ${_currentPage + 1}/$_totalPages',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: themeInfo.textColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
