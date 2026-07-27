import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
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
  late final ValueNotifier<bool> _showOverlayNotifier;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<int> _totalPagesNotifier;
  late final ValueNotifier<bool> _isAutoScrollingNotifier;
  late final ValueNotifier<UnifiedEpisode> _currentEpisodeNotifier;

  Timer? _autoScrollTimer;

  Offset? _pointerDownPos;

  late final FocusNode _focusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ScrollOffsetController _scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late final PageController _pageController;
  late final MediaArgs _matchArgs;

  @override
  void initState() {
    super.initState();
    _enableImmersiveMode();
    try {
      if (ref.read(readerPrefsProvider).keepScreenOn) {
        WakelockPlus.enable();
      }
    } catch (_) {}
    _focusNode.requestFocus();
    HardwareKeyboard.instance.addHandler(_onScreenKeyEvent);

    _showOverlayNotifier = ValueNotifier(false);
    _currentPageNotifier = ValueNotifier(
      widget.mode.startPosition == -1
          ? -1
          : (widget.mode.startPosition > 0 ? widget.mode.startPosition - 1 : 0),
    );
    _totalPagesNotifier = ValueNotifier(0);
    _isAutoScrollingNotifier = ValueNotifier(false);
    _currentEpisodeNotifier = ValueNotifier(widget.mode.episode);

    _matchArgs = MediaArgs(
      mediaTitle: widget.mode.media.title.availableTitle,
      type: widget.mode.media.type,
    );

    _pageController = PageController(
      initialPage: _currentPageNotifier.value == -1
          ? 0
          : _currentPageNotifier.value,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onScreenKeyEvent);
    _focusNode.dispose();
    _pageController.dispose();
    _disableImmersiveMode();

    _showOverlayNotifier.dispose();
    _currentPageNotifier.dispose();
    _totalPagesNotifier.dispose();
    _isAutoScrollingNotifier.dispose();
    _currentEpisodeNotifier.dispose();

    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  bool _onScreenKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final prefs = ref.read(readerPrefsProvider);
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      if (_currentPageNotifier.value > 0) {
        _jumpToPage(_currentPageNotifier.value - 1, prefs.direction);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.space) {
      if (_currentPageNotifier.value < _totalPagesNotifier.value - 1) {
        _jumpToPage(_currentPageNotifier.value + 1, prefs.direction);
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
    if (key == LogicalKeyboardKey.end && _totalPagesNotifier.value > 0) {
      _jumpToPage(_totalPagesNotifier.value - 1, prefs.direction);
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

    if (_isAutoScrollingNotifier.value) {
      _autoScrollTimer?.cancel();
      _isAutoScrollingNotifier.value = false;
    } else {
      _isAutoScrollingNotifier.value = true;
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
            !_isAutoScrollingNotifier.value ||
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
        if (!mounted || !_isAutoScrollingNotifier.value) {
          timer.cancel();
          return;
        }
        if (_currentPageNotifier.value < _totalPagesNotifier.value - 1) {
          _jumpToPage(_currentPageNotifier.value + 1, prefs.direction);
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
    if (_isAutoScrollingNotifier.value) {
      _startAutoScroll();
    }
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
    _showOverlayNotifier.value = !_showOverlayNotifier.value;
    _showOverlayNotifier.value
        ? _disableImmersiveMode()
        : _enableImmersiveMode();
  }

  void _onPageChanged(int index) {
    if (_currentPageNotifier.value == index) return;
    _currentPageNotifier.value = index;
    _saveHistory();
  }

  void _saveHistory() {
    if (_totalPagesNotifier.value == 0) return;

    final savedPageNumber = _currentPageNotifier.value + 1;

    final entry = ReadHistoryEntry()
      ..chapterNumber = widget.mode.episode.number
      ..mangaId = widget.mode.media.id
      ..mangaTitle = widget.mode.media.title.availableTitle
      ..cover = widget.mode.media.cover
      ..banner = widget.mode.media.banner
      ..positionPage = savedPageNumber
      ..totalPages = _totalPagesNotifier.value
      ..sourceId = widget.mode.sourceInfo.id
      ..sourceName = widget.mode.sourceInfo.name
      ..providerId = widget.mode.media.providerId != widget.mode.media.id
          ? widget.mode.media.providerId
          : null
      ..lastUpdated = DateTime.now();

    ref.read(readHistoryRepositoryProvider).saveProgress(entry);

    ref
        .read(syncEngineProvider)
        .processReading(
          media: widget.mode.media,
          chapterNumber: _currentEpisodeNotifier.value.number,
          positionPage: savedPageNumber,
          totalPages: _totalPagesNotifier.value,
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

  Future<void> _skipToChapter(
    EpisodesListState? episodesState, {
    required bool next,
  }) async {
    if (episodesState == null) return;

    final currentNum = _currentEpisodeNotifier.value.number;
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

    await ref
        .read(readerProvider(widget.mode).notifier)
        .loadAdjacentChapter(target, next: next);
  }

  void _showChaptersSheet(EpisodesListState? episodesState) {
    if (episodesState == null) return;

    AppBottomSheet.show(
      context: context,
      title: 'Chapters',
      child: ChaptersBottomSheet(
        matchArgs: _matchArgs,
        currentEpisode: _currentEpisodeNotifier.value,
        mediaId: widget.mode.media.id,
        sourceInfo: episodesState.source,
        onEpisodeSelected: (ep) => _navigateToEpisode(ep, episodesState.source),
      ),
    );
  }

  void _updateTotalPagesIfNeeded(int count) {
    if (_totalPagesNotifier.value != count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _totalPagesNotifier.value = count;
          if (_currentPageNotifier.value == -1) {
            _currentPageNotifier.value = count - 1;
            if (ref.read(readerPrefsProvider).direction !=
                ReaderDirection.webtoon) {
              final hasPrev =
                  _getAdjacentChapterName(
                    ref.read(episodesListProvider(_matchArgs)).value,
                    next: false,
                  ) !=
                  null;
              if (_pageController.hasClients) {
                _pageController.jumpToPage(
                  _currentPageNotifier.value + (hasPrev ? 1 : 0),
                );
              }
            }
          }
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

  String? _getAdjacentChapterName(
    EpisodesListState? episodesState, {
    required bool next,
  }) {
    if (episodesState == null) return null;

    final currentNum = widget.mode.episode.number;
    final adjacentEps = episodesState.episodes
        .where((e) => next ? e.number > currentNum : e.number < currentNum)
        .toList();

    if (adjacentEps.isEmpty) return null;

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

    return target.title != null && target.title!.isNotEmpty
        ? target.title
        : 'Chapter ${target.number}';
  }

  void _jumpToPage(int newPage, ReaderDirection direction) {
    final episodesState = ref.read(episodesListProvider(_matchArgs)).value;
    final hasPrev = _getAdjacentChapterName(episodesState, next: false) != null;
    final targetIndex = newPage + (hasPrev ? 1 : 0);

    if (direction == ReaderDirection.webtoon) {
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: targetIndex);
      }
    } else {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      }
    }
    _currentPageNotifier.value = newPage;
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

    if (_isAutoScrollingNotifier.value &&
        readerPrefs.direction != ReaderDirection.webtoon) {
      _autoScrollTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isAutoScrollingNotifier.value) {
          _isAutoScrollingNotifier.value = false;
        }
      });
    }

    final themeInfo = _getThemeInfo(readerPrefs.backgroundColor);

    return Scaffold(
      backgroundColor: themeInfo.bgColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
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
                      if (readerPrefs.tapToTurnPage &&
                          !_showOverlayNotifier.value) {
                        if (event.position.dx < width * 0.3) {
                          if (_currentPageNotifier.value > 0) {
                            _jumpToPage(
                              _currentPageNotifier.value - 1,
                              readerPrefs.direction,
                            );
                          } else {
                            _skipToChapter(episodesState, next: false);
                          }
                        } else if (event.position.dx > width * 0.7) {
                          if (_currentPageNotifier.value <
                              _totalPagesNotifier.value - 1) {
                            _jumpToPage(
                              _currentPageNotifier.value + 1,
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
                child: ValueListenableBuilder<UnifiedEpisode>(
                  valueListenable: _currentEpisodeNotifier,
                  builder: (context, currentEpisode, child) {
                    return ReaderContent(
                      stateAsync: readerStateAsync,
                      prefs: readerPrefs,
                      textColor: themeInfo.textColor,
                      initialPage: _currentPageNotifier.value,
                      itemScrollController: _itemScrollController,
                      scrollOffsetController: _scrollOffsetController,
                      itemPositionsListener: _itemPositionsListener,
                      pageController: _pageController,
                      onTotalPagesUpdated: _updateTotalPagesIfNeeded,
                      onPageChanged: _onPageChanged,
                      onRetry: () => ref
                          .read(readerProvider(widget.mode).notifier)
                          .retry(),
                      mediaTitle: widget.mode.media.title.availableTitle,
                      currentEpisode: currentEpisode,
                      currentChapterName:
                          currentEpisode.title != null &&
                              currentEpisode.title!.isNotEmpty
                          ? currentEpisode.title!
                          : 'Chapter ${currentEpisode.number}',
                      nextChapterName: _getAdjacentChapterName(
                        episodesState,
                        next: true,
                      ),
                      prevChapterName: _getAdjacentChapterName(
                        episodesState,
                        next: false,
                      ),
                      onChapterChanged: (ep) {
                        if (mounted) {
                          if (_currentEpisodeNotifier.value.id == ep.id) return;

                          _currentEpisodeNotifier.value = ep;

                          final readerState = ref
                              .read(readerProvider(widget.mode))
                              .value;
                          if (readerState != null) {
                            if (readerState.nextChapterData?.episode.id ==
                                ep.id) {
                              final oldCurrentLength =
                                  readerState
                                      .currentChapterData
                                      ?.pages
                                      .length ??
                                  0;
                              final jumpIndex =
                                  oldCurrentLength +
                                  2 +
                                  _currentPageNotifier.value;

                              double topAlignment = 0.0;
                              if (readerPrefs.direction ==
                                  ReaderDirection.webtoon) {
                                final positions =
                                    _itemPositionsListener.itemPositions.value;
                                if (positions.isNotEmpty) {
                                  final topItem = positions
                                      .where((p) => p.itemTrailingEdge > 0)
                                      .reduce(
                                        (min, p) =>
                                            p.itemLeadingEdge <
                                                min.itemLeadingEdge
                                            ? p
                                            : min,
                                      );
                                  topAlignment = topItem.itemLeadingEdge;
                                }
                              }

                              ref
                                  .read(readerProvider(widget.mode).notifier)
                                  .shiftNext();

                              if (readerPrefs.direction ==
                                  ReaderDirection.webtoon) {
                                if (_itemScrollController.isAttached) {
                                  _itemScrollController.jumpTo(
                                    index: jumpIndex,
                                    alignment: topAlignment,
                                  );
                                }
                              } else {
                                if (_pageController.hasClients) {
                                  _pageController.jumpToPage(jumpIndex);
                                }
                              }

                              _skipToChapter(episodesState, next: true);
                            } else if (readerState
                                    .prevChapterData
                                    ?.episode
                                    .id ==
                                ep.id) {
                              final currentNum = ep.number;
                              final reallyHasPrev =
                                  episodesState?.episodes.any(
                                    (e) => e.number < currentNum,
                                  ) ??
                                  false;

                              final jumpIndex =
                                  (reallyHasPrev ? 1 : 0) +
                                  _currentPageNotifier.value;

                              double topAlignment = 0.0;
                              if (readerPrefs.direction ==
                                  ReaderDirection.webtoon) {
                                final positions =
                                    _itemPositionsListener.itemPositions.value;
                                if (positions.isNotEmpty) {
                                  final topItem = positions
                                      .where((p) => p.itemTrailingEdge > 0)
                                      .reduce(
                                        (min, p) =>
                                            p.itemLeadingEdge <
                                                min.itemLeadingEdge
                                            ? p
                                            : min,
                                      );
                                  topAlignment = topItem.itemLeadingEdge;
                                }
                              }

                              ref
                                  .read(readerProvider(widget.mode).notifier)
                                  .shiftPrev();

                              if (readerPrefs.direction ==
                                  ReaderDirection.webtoon) {
                                if (_itemScrollController.isAttached) {
                                  _itemScrollController.jumpTo(
                                    index: jumpIndex,
                                    alignment: topAlignment,
                                  );
                                }
                              } else {
                                if (_pageController.hasClients) {
                                  _pageController.jumpToPage(jumpIndex);
                                }
                              }

                              _skipToChapter(episodesState, next: false);
                            }
                          }
                        }
                      },
                      onNextChapter: () =>
                          _skipToChapter(episodesState, next: true),
                      onPrevChapter: () =>
                          _skipToChapter(episodesState, next: false),
                    );
                  },
                ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showOverlayNotifier,
            builder: (context, showOverlay, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                top: showOverlay ? 0 : -100,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !showOverlay,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: showOverlay ? 1.0 : 0.0,
                    child: ValueListenableBuilder<UnifiedEpisode>(
                      valueListenable: _currentEpisodeNotifier,
                      builder: (context, currentEpisode, child) {
                        return ReaderAppBar(
                          mediaTitle: widget.mode.media.title.availableTitle,
                          episodeNumber: currentEpisode.number,
                          themeInfo: themeInfo,
                          uiRoundness: GlobalUI.uiRoundness,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: _totalPagesNotifier,
            builder: (context, totalPages, child) {
              if (totalPages == 0) return const SizedBox.shrink();

              return ValueListenableBuilder<bool>(
                valueListenable: _showOverlayNotifier,
                builder: (context, showOverlay, child) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    bottom: showOverlay ? 0 : -160,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !showOverlay,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: showOverlay ? 1.0 : 0.0,
                        child: ValueListenableBuilder<int>(
                          valueListenable: _currentPageNotifier,
                          builder: (context, currentPage, child) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: _isAutoScrollingNotifier,
                              builder: (context, isAutoScrolling, child) {
                                return ReaderBottomOverlay(
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                  hasPrevChapter: _hasChapter(
                                    episodesState,
                                    next: false,
                                  ),
                                  hasNextChapter: _hasChapter(
                                    episodesState,
                                    next: true,
                                  ),
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
                                      isAutoScrolling &&
                                      readerPrefs.direction ==
                                          ReaderDirection.webtoon,
                                  autoScrollSpeed: readerPrefs.autoScrollSpeed,
                                  onToggleAutoScroll:
                                      readerPrefs.direction ==
                                          ReaderDirection.webtoon
                                      ? _toggleAutoScroll
                                      : null,
                                  onChangeAutoScrollSpeed:
                                      readerPrefs.direction ==
                                          ReaderDirection.webtoon
                                      ? _changeAutoScrollSpeed
                                      : null,
                                  onPrevChapter: () => _skipToChapter(
                                    episodesState,
                                    next: false,
                                  ),
                                  onNextChapter: () =>
                                      _skipToChapter(episodesState, next: true),
                                  onChaptersTap: () =>
                                      _showChaptersSheet(episodesState),
                                  onPageChanged: (newPage) => _jumpToPage(
                                    newPage,
                                    readerPrefs.direction,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showOverlayNotifier,
            builder: (context, showOverlay, child) {
              if (showOverlay || !readerPrefs.showMiniStatus) {
                return const SizedBox.shrink();
              }

              return ValueListenableBuilder<int>(
                valueListenable: _totalPagesNotifier,
                builder: (context, totalPages, child) {
                  if (totalPages == 0) return const SizedBox.shrink();

                  return AnimatedPositioned(
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
                          borderRadius: BorderRadius.circular(
                            GlobalUI.uiRoundness,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isAutoScrollingNotifier,
                          builder: (context, isAutoScrolling, child) {
                            return ValueListenableBuilder<int>(
                              valueListenable: _currentPageNotifier,
                              builder: (context, currentPage, child) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isAutoScrolling &&
                                        readerPrefs.direction ==
                                            ReaderDirection.webtoon) ...[
                                      Icon(
                                        Icons.play_circle_filled_rounded,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      'Ch. ${widget.mode.episode.number} • ${currentPage + 1}/$totalPages',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: themeInfo.textColor.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
