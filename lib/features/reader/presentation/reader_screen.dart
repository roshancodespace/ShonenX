import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/reader/providers/reader_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/features/discord/providers/discord_rpc_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

import 'widgets/chapters_bottom_sheet.dart';
import 'widgets/reader_app_bar.dart';
import 'widgets/reader_bottom_overlay.dart';
import 'widgets/reader_page_view.dart';
import 'widgets/reader_theme_info.dart';
import 'widgets/reader_webtoon_view.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final ReaderModeOnline mode;

  const ReaderScreen({super.key, required this.mode});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final FocusNode _focusNode;
  late final MediaArgs _matchArgs;
  late PageController _pageController;
  GlobalKey<ReaderWebtoonViewState> _webtoonKey = GlobalKey();

  Offset? _pointerDownPos;

  @override
  void initState() {
    super.initState();
    _enableImmersiveMode();
    _tryEnableWakelock();

    _focusNode = FocusNode()..requestFocus();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);

    final startPage = widget.mode.startPosition == -1
        ? 0
        : (widget.mode.startPosition > 0 ? widget.mode.startPosition - 1 : 0);
    _pageController = PageController(initialPage: startPage);

    _matchArgs = MediaArgs(
      mediaTitle: widget.mode.media.title.availableTitle,
      type: widget.mode.media.type,
    );
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode.episode.id != widget.mode.episode.id) {
      _webtoonKey = GlobalKey<ReaderWebtoonViewState>();
      final startPage = widget.mode.startPosition == -1
          ? 0
          : (widget.mode.startPosition > 0 ? widget.mode.startPosition - 1 : 0);
      _pageController.dispose();
      _pageController = PageController(initialPage: startPage);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _focusNode.dispose();
    _pageController.dispose();
    _disableImmersiveMode();
    try {
      ref.read(discordRpcProvider.notifier).updateMediaPresence(widget.mode.media);
    } catch (_) {}
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  void _updateDiscordRpc(ReaderState state) {
    ref.read(discordRpcProvider.notifier).updateMangaPresence(
      manga: widget.mode.media,
      chapterNumber: widget.mode.episode.number.toInt(),
      chapterTitle: widget.mode.episode.title,
      currentPage: state.currentPage + 1,
      totalPages: state.totalPages > 0 ? state.totalPages : null,
    );
  }

  // ──────────────── System UI ────────────────

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

  void _tryEnableWakelock() {
    try {
      if (ref.read(readerPrefsProvider).keepScreenOn) {
        WakelockPlus.enable();
      }
    } catch (_) {}
  }

  // ──────────────── Controls ────────────────

  void _toggleOverlay() {
    final controller = ref.read(readerProvider(widget.mode).notifier);
    final currentShow = ref.read(readerProvider(widget.mode)).showOverlay;
    controller.setOverlay(!currentShow);
    !currentShow ? _disableImmersiveMode() : _enableImmersiveMode();
  }

  void _goToPage(int page, ReaderDirection direction) {
    final state = ref.read(readerProvider(widget.mode));
    if (page < 0 || page >= state.totalPages) return;

    if (direction == ReaderDirection.webtoon) {
      _webtoonKey.currentState?.jumpToPage(page);
    } else {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(page);
      }
    }
    ref.read(readerProvider(widget.mode).notifier).setPage(page);
  }

  // ──────────────── Keyboard ────────────────

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final prefs = ref.read(readerPrefsProvider);
    final state = ref.read(readerProvider(widget.mode));
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _goToPage(state.currentPage - 1, prefs.direction);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.space) {
      if (state.currentPage < state.totalPages - 1) {
        _goToPage(state.currentPage + 1, prefs.direction);
      } else {
        _skipToChapter(next: true);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.keyF || key == LogicalKeyboardKey.f11) {
      _toggleOverlay();
      return true;
    }
    if (key == LogicalKeyboardKey.keyN) {
      _skipToChapter(next: true);
      return true;
    }
    if (key == LogicalKeyboardKey.keyP) {
      _skipToChapter(next: false);
      return true;
    }
    return false;
  }

  // ──────────────── Chapter Navigation ────────────────

  void _skipToChapter({required bool next}) {
    final episodesState = ref.read(episodesListProvider(_matchArgs)).value;
    if (episodesState == null) return;

    final currentNum = widget.mode.episode.number;
    final adjacentEps = episodesState.episodes
        .where((e) => next ? e.number > currentNum : e.number < currentNum)
        .toList();

    if (adjacentEps.isEmpty) return;

    final targetNum = next ? adjacentEps.first.number : adjacentEps.last.number;
    final candidates = adjacentEps.where((e) => e.number == targetNum).toList();

    final prefScanlator = ref.read(
      preferredScanlatorProvider(widget.mode.media.id),
    );
    final target = candidates.firstWhere(
      (e) => e.scanlator == prefScanlator,
      orElse: () => candidates.first,
    );

    _navigateToEpisode(target, episodesState.source);
  }

  bool _hasChapter({required bool next}) {
    final episodesState = ref.read(episodesListProvider(_matchArgs)).value;
    if (episodesState == null) return false;
    final currentNum = widget.mode.episode.number;
    return episodesState.episodes.any(
      (e) => next ? e.number > currentNum : e.number < currentNum,
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

  void _showChaptersSheet() {
    final episodesState = ref.read(episodesListProvider(_matchArgs)).value;
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

  // ──────────────── Theme ────────────────

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

  // ──────────────── Build ────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider(widget.mode));
    final prefs = ref.watch(readerPrefsProvider);
    final themeInfo = _getThemeInfo(prefs.backgroundColor);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDiscordRpc(state);
    });

    return Scaffold(
      backgroundColor: themeInfo.bgColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Main Content ──
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            removeLeft: true,
            removeRight: true,
            child: KeyboardListener(
              focusNode: _focusNode,
              child: Listener(
                onPointerDown: (e) => _pointerDownPos = e.position,
                onPointerUp: (e) => _handleTap(e, prefs, state),
                child: state.pages.when(
                  data: (pages) =>
                      _buildReaderView(pages, prefs, themeInfo, state),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _buildError(err.toString(), themeInfo),
                ),
              ),
            ),
          ),

          // ── Top Overlay (App Bar) ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            top: state.showOverlay ? 0 : -100,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !state.showOverlay,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: state.showOverlay ? 1.0 : 0.0,
                child: ReaderAppBar(
                  mediaTitle: widget.mode.media.title.availableTitle,
                  episodeNumber: widget.mode.episode.number,
                  themeInfo: themeInfo,
                  uiRoundness: GlobalUI.uiRoundness,
                ),
              ),
            ),
          ),

          // ── Bottom Overlay (Controls) ──
          if (state.totalPages > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              bottom: state.showOverlay ? 0 : -160,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !state.showOverlay,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: state.showOverlay ? 1.0 : 0.0,
                  child: ReaderBottomOverlay(
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    hasPrevChapter: _hasChapter(next: false),
                    hasNextChapter: _hasChapter(next: true),
                    appBarBg: themeInfo.appBarBg,
                    textColor: themeInfo.textColor,
                    uiRoundness: GlobalUI.uiRoundness,
                    onPrevChapter: () => _skipToChapter(next: false),
                    onNextChapter: () => _skipToChapter(next: true),
                    onChaptersTap: _showChaptersSheet,
                    onPageChanged: (page) => _goToPage(page, prefs.direction),
                  ),
                ),
              ),
            ),

          // ── Mini Status Pill ──
          if (!state.showOverlay &&
              prefs.showMiniStatus &&
              state.totalPages > 0)
            Positioned(
              bottom: 16,
              right: 16,
              child: IgnorePointer(
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
                  child: Text(
                    'Ch. ${widget.mode.episode.number} • ${state.currentPage + 1}/${state.totalPages}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: themeInfo.textColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────── Sub-builders ────────────────

  Widget _buildReaderView(
    List<ChapterPage> pages,
    ReaderPrefState prefs,
    ReaderThemeInfo themeInfo,
    ReaderState state,
  ) {
    if (prefs.direction == ReaderDirection.webtoon) {
      return ReaderWebtoonView(
        key: _webtoonKey,
        pages: pages,
        initialPage: state.currentPage,
        scaleType: prefs.scaleType,
        textColor: themeInfo.textColor,
        onPageChanged: (page) =>
            ref.read(readerProvider(widget.mode).notifier).setPage(page),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != state.currentPage) {
        _pageController.jumpToPage(state.currentPage);
      }
    });

    return ReaderPageView(
      key: ValueKey('${widget.mode.episode.id}_${prefs.direction.name}'),
      pages: pages,
      controller: _pageController,
      direction: prefs.direction,
      scaleType: prefs.scaleType,
      textColor: themeInfo.textColor,
      onPageChanged: (page) =>
          ref.read(readerProvider(widget.mode).notifier).setPage(page),
    );
  }

  Widget _buildError(String error, ReaderThemeInfo themeInfo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load pages:\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: themeInfo.textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(readerProvider(widget.mode).notifier).retry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleTap(
    PointerUpEvent event,
    ReaderPrefState prefs,
    ReaderState state,
  ) {
    if (_pointerDownPos == null) return;

    final distance = (event.position - _pointerDownPos!).distance;
    if (distance >= 10) return;

    final width = MediaQuery.of(context).size.width;

    if (prefs.tapToTurnPage && !state.showOverlay) {
      if (event.position.dx < width * 0.3) {
        if (state.currentPage > 0) {
          _goToPage(state.currentPage - 1, prefs.direction);
        } else {
          _skipToChapter(next: false);
        }
      } else if (event.position.dx > width * 0.7) {
        if (state.currentPage < state.totalPages - 1) {
          _goToPage(state.currentPage + 1, prefs.direction);
        } else {
          _skipToChapter(next: true);
        }
      } else {
        _toggleOverlay();
      }
    } else {
      _toggleOverlay();
    }
  }
}
