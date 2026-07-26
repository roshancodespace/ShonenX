import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class ChapterData {
  final UnifiedEpisode episode;
  final List<ChapterPage> pages;

  const ChapterData({required this.episode, required this.pages});
}

class ReaderState {
  final ChapterData? prevChapterData;
  final ChapterData? currentChapterData;
  final ChapterData? nextChapterData;
  final bool isLoading;
  final String? error;

  const ReaderState({
    this.prevChapterData,
    this.currentChapterData,
    this.nextChapterData,
    this.isLoading = true,
    this.error,
  });

  ReaderState copyWith({
    ChapterData? Function()? prevChapterData,
    ChapterData? Function()? currentChapterData,
    ChapterData? Function()? nextChapterData,
    bool? isLoading,
    String? error,
  }) {
    return ReaderState(
      prevChapterData: prevChapterData != null
          ? prevChapterData()
          : this.prevChapterData,
      currentChapterData: currentChapterData != null
          ? currentChapterData()
          : this.currentChapterData,
      nextChapterData: nextChapterData != null
          ? nextChapterData()
          : this.nextChapterData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReaderNotifier extends AsyncNotifier<ReaderState> {
  late ReaderModeOnline mode;
  bool _isLoadingAdjacent = false;

  ReaderNotifier(this.mode);

  @override
  Future<ReaderState> build() async {
    return _fetchInitial();
  }

  Future<ReaderState> _fetchInitial() async {
    try {
      final source = ref.read(mangaSourceProvider(mode.sourceInfo));
      final pages = await source.getPages(mode.episode.id);

      if (pages.isEmpty) {
        return const ReaderState(isLoading: false, error: 'No pages found.');
      }

      return ReaderState(
        isLoading: false,
        currentChapterData: ChapterData(episode: mode.episode, pages: pages),
      );
    } catch (e) {
      return ReaderState(isLoading: false, error: e.toString());
    }
  }

  Future<void> retry() async {
    state = const AsyncData(ReaderState(isLoading: true));
    state = AsyncData(await _fetchInitial());
  }

  Future<void> loadAdjacentChapter(
    UnifiedEpisode nextEpisode, {
    required bool next,
  }) async {
    if (state.value == null || state.value!.isLoading || _isLoadingAdjacent)
      return;
    final currentState = state.value!;

    // Already loaded?
    if (next) {
      if (currentState.nextChapterData?.episode.id == nextEpisode.id) return;
    } else {
      if (currentState.prevChapterData?.episode.id == nextEpisode.id) return;
    }

    _isLoadingAdjacent = true;
    try {
      final source = ref.read(mangaSourceProvider(mode.sourceInfo));
      final pages = await source.getPages(nextEpisode.id);

      if (pages.isNotEmpty) {
        if (next) {
          state = AsyncData(
            currentState.copyWith(
              nextChapterData: () =>
                  ChapterData(episode: nextEpisode, pages: pages),
            ),
          );
        } else {
          state = AsyncData(
            currentState.copyWith(
              prevChapterData: () =>
                  ChapterData(episode: nextEpisode, pages: pages),
            ),
          );
        }
      }
    } finally {
      _isLoadingAdjacent = false;
    }
  }

  void shiftNext() {
    if (state.value == null) return;
    final currentState = state.value!;

    state = AsyncData(
      currentState.copyWith(
        prevChapterData: () => currentState.currentChapterData,
        currentChapterData: () => currentState.nextChapterData,
        nextChapterData: () => null,
      ),
    );
  }

  void shiftPrev() {
    if (state.value == null) return;
    final currentState = state.value!;

    state = AsyncData(
      currentState.copyWith(
        nextChapterData: () => currentState.currentChapterData,
        currentChapterData: () => currentState.prevChapterData,
        prevChapterData: () => null,
      ),
    );
  }
}

final readerProvider =
    AsyncNotifierProvider.family<ReaderNotifier, ReaderState, ReaderModeOnline>(
      ReaderNotifier.new,
      name: 'readerProvider',
    );
