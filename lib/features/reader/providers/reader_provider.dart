import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class ReaderState {
  final ReaderModeOnline mode;
  final AsyncValue<List<ChapterPage>> pages;
  final int currentPage;
  final int totalPages;
  final bool showOverlay;

  const ReaderState({
    required this.mode,
    this.pages = const AsyncValue.loading(),
    this.currentPage = 0,
    this.totalPages = 0,
    this.showOverlay = false,
  });

  ReaderState copyWith({
    ReaderModeOnline? mode,
    AsyncValue<List<ChapterPage>>? pages,
    int? currentPage,
    int? totalPages,
    bool? showOverlay,
  }) {
    return ReaderState(
      mode: mode ?? this.mode,
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      showOverlay: showOverlay ?? this.showOverlay,
    );
  }
}

class ReaderNotifier extends Notifier<ReaderState> {
  late final ReaderModeOnline arg;

  ReaderNotifier(this.arg);

  @override
  ReaderState build() {
    final startPage = arg.startPosition == -1
        ? 0
        : (arg.startPosition > 0 ? arg.startPosition - 1 : 0);

    Future.microtask(() => _fetchPages(arg));

    return ReaderState(
      mode: arg,
      currentPage: startPage,
      totalPages: 0,
      showOverlay: false,
    );
  }

  Future<void> _fetchPages(ReaderModeOnline mode) async {
    state = state.copyWith(pages: const AsyncValue.loading());
    try {
      final source = ref.read(mangaSourceProvider(mode.sourceInfo));
      final pageList = await source.getPages(mode.episode.id);

      if (pageList.isEmpty) {
        state = state.copyWith(
          pages: AsyncValue.error(
            Exception('No pages found for this chapter.'),
            StackTrace.current,
          ),
        );
        return;
      }

      final startPage = mode.startPosition == -1
          ? pageList.length - 1
          : (mode.startPosition > 0 ? mode.startPosition - 1 : 0).clamp(
              0,
              pageList.length - 1,
            );

      state = state.copyWith(
        pages: AsyncValue.data(pageList),
        totalPages: pageList.length,
        currentPage: startPage,
      );

      _saveHistory(startPage, pageList.length);
    } catch (e, st) {
      state = state.copyWith(pages: AsyncValue.error(e, st));
    }
  }

  void setPage(int page) {
    if (page < 0 || (state.totalPages > 0 && page >= state.totalPages)) return;
    if (state.currentPage == page) return;

    state = state.copyWith(currentPage: page);
    _saveHistory(page, state.totalPages);
  }

  void toggleOverlay() {
    state = state.copyWith(showOverlay: !state.showOverlay);
  }

  void setOverlay(bool show) {
    state = state.copyWith(showOverlay: show);
  }

  void retry() {
    _fetchPages(arg);
  }

  void _saveHistory(int pageIndex, int total) {
    if (total == 0) return;
    final savedPageNumber = pageIndex + 1;

    final entry = ReadHistoryEntry()
      ..chapterNumber = arg.episode.number
      ..mangaId = arg.media.id
      ..mangaTitle = arg.media.title.availableTitle
      ..cover = arg.media.cover
      ..banner = arg.media.banner
      ..positionPage = savedPageNumber
      ..totalPages = total
      ..sourceId = arg.sourceInfo.id
      ..sourceName = arg.sourceInfo.name
      ..providerId = arg.media.providerId != arg.media.id
          ? arg.media.providerId
          : null
      ..lastUpdated = DateTime.now();

    ref.read(readHistoryRepositoryProvider).saveProgress(entry);
    ref
        .read(syncEngineProvider)
        .processReading(
          media: arg.media,
          chapterNumber: arg.episode.number,
          positionPage: savedPageNumber,
          totalPages: total,
        );
  }
}

final readerProvider = NotifierProvider.autoDispose
    .family<ReaderNotifier, ReaderState, ReaderModeOnline>(
      ReaderNotifier.new,
      name: 'readerProvider',
    );
