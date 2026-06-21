import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/reader/providers/reader_provider.dart';
import 'package:shonenx/features/settings/presentation/reader_settings_screen.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

import 'widgets/chapters_bottom_sheet.dart';
import 'widgets/reader_bottom_overlay.dart';
import 'widgets/reader_image.dart';

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

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  PageController? _pageController;
  late final MatchArgs _matchArgs;

  @override
  void initState() {
    super.initState();
    _enableImmersiveMode();
    _itemPositionsListener.itemPositions.addListener(_onWebtoonScroll);
    _matchArgs = MatchArgs(
      mediaTitle: widget.mode.media.title.availableTitle,
      type: widget.mode.media.type,
    );
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onWebtoonScroll);
    _pageController?.dispose();
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
    if (positions.isEmpty) return;

    final first = positions
        .where((p) => p.itemTrailingEdge > 0)
        .reduce((min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min);

    if (_currentPage != first.index) {
      setState(() => _currentPage = first.index);
      _saveHistory();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _saveHistory();
  }

  void _saveHistory() {
    if (_totalPages == 0) return;

    final entry = ReadHistoryEntry()
      ..chapterNumber = widget.mode.episode.number
      ..mangaId = widget.mode.media.id
      ..mangaTitle = widget.mode.media.title.availableTitle
      ..cover = widget.mode.media.cover
      ..banner = widget.mode.media.banner
      ..positionPage = _currentPage
      ..totalPages = _totalPages
      ..lastUpdated = DateTime.now();

    ref.read(readHistoryRepositoryProvider).saveProgress(entry);
    ref
        .read(syncEngineProvider)
        .processReading(
          media: widget.mode.media,
          chapterNumber: widget.mode.episode.number,
          positionPage: _currentPage,
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

  @override
  Widget build(BuildContext context) {
    final readerStateAsync = ref.watch(readerProvider(widget.mode));
    final readerPrefs = ref.watch(readerPrefsProvider);
    final episodesState = ref.watch(episodesListProvider(_matchArgs)).value;

    final themeInfo = _getThemeInfo(readerPrefs.backgroundColor);

    return Scaffold(
      backgroundColor: themeInfo.bgColor,
      extendBodyBehindAppBar: true,
      appBar: _showOverlay ? _buildAppBar(themeInfo) : null,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _toggleOverlay,
              child: _buildReaderContent(
                readerStateAsync,
                readerPrefs,
                themeInfo.textColor,
              ),
            ),
            if (_showOverlay && _totalPages > 0)
              ReaderBottomOverlay(
                currentPage: _currentPage,
                totalPages: _totalPages,
                hasPrevChapter: _hasChapter(episodesState, next: false),
                hasNextChapter: _hasChapter(episodesState, next: true),
                currentEpisode: widget.mode.episode,
                appBarBg: themeInfo.appBarBg,
                textColor: themeInfo.textColor,
                onPrevChapter: () => _skipToChapter(episodesState, next: false),
                onNextChapter: () => _skipToChapter(episodesState, next: true),
                onChaptersTap: () => _showChaptersSheet(episodesState),
                onPageChanged: (newPage) =>
                    _jumpToPage(newPage, readerPrefs.direction),
              ),
          ],
        ),
      ),
    );
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

  PreferredSizeWidget _buildAppBar(ReaderThemeInfo themeInfo) {
    final theme = Theme.of(context);
    final episodeNumber = widget.mode.episode.number;
    final displayChapter = episodeNumber.toString().contains('.0')
        ? episodeNumber.toInt().toString()
        : episodeNumber.toString();

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.mode.media.title.availableTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 14,
              color: themeInfo.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Chapter $displayChapter',
            style: theme.textTheme.labelMedium?.copyWith(
              color: themeInfo.textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      backgroundColor: themeInfo.appBarBg,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: themeInfo.textColor),
      leading: IconButton(
        onPressed: context.pop,
        icon: const Icon(Icons.arrow_back_ios_new_outlined),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => AppBottomSheet.show(
            context: context,
            title: 'Reader Settings',
            child: const ReaderSettingsContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildReaderContent(
    AsyncValue<ReaderState> stateAsync,
    ReaderPrefState prefs,
    Color textColor,
  ) {
    return stateAsync.when(
      data: (state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return _buildErrorState(state.error!, textColor);
        }
        if (state.pages.isEmpty) {
          return Center(
            child: Text('No pages found.', style: TextStyle(color: textColor)),
          );
        }

        _updateTotalPagesIfNeeded(state.pages.length);

        final isWebtoon = prefs.direction == ReaderDirection.webtoon;
        Widget content = isWebtoon
            ? _buildWebtoonList(state.pages, prefs, textColor)
            : _buildPageView(state.pages, prefs, textColor);

        if (isWebtoon &&
            (ResponsiveData.from(context).isDesktop ||
                ResponsiveData.from(context).isTablet)) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: content,
            ),
          );
        }

        return content;
      },
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load pages:\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
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

  Widget _buildWebtoonList(
    List<ChapterPage> pages,
    ReaderPrefState prefs,
    Color textColor,
  ) {
    return ScrollablePositionedList.builder(
      itemCount: pages.length,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemBuilder: (context, index) {
        final page = pages[index];
        return ReaderImage(
          url: page.url,
          headers: page.headers ?? const {},
          index: index,
          scaleType: prefs.scaleType,
          textColor: textColor,
        );
      },
    );
  }

  Widget _buildPageView(
    List<ChapterPage> pages,
    ReaderPrefState prefs,
    Color textColor,
  ) {
    _pageController ??= PageController(initialPage: _currentPage);
    return PageView.builder(
      controller: _pageController,
      reverse: prefs.direction == ReaderDirection.rtl,
      itemCount: pages.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final page = pages[index];
        return Center(
          child: ReaderImage(
            url: page.url,
            headers: page.headers ?? const {},
            index: index,
            scaleType: prefs.scaleType,
            textColor: textColor,
          ),
        );
      },
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
      _pageController?.jumpToPage(newPage);
    }
    setState(() => _currentPage = newPage);
  }
}

class ReaderThemeInfo {
  final Color bgColor;
  final Color appBarBg;
  final Color textColor;

  const ReaderThemeInfo({
    required this.bgColor,
    required this.appBarBg,
    required this.textColor,
  });
}
