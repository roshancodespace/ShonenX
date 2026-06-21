import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class ReaderState {
  final List<ChapterPage> pages;
  final bool isLoading;
  final String? error;

  const ReaderState({this.pages = const [], this.isLoading = true, this.error});

  ReaderState copyWith({List<ChapterPage>? pages, bool? isLoading, String? error}) {
    return ReaderState(
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReaderNotifier extends AsyncNotifier<ReaderState> {
  late ReaderModeOnline mode;

  ReaderNotifier(this.mode);

  @override
  Future<ReaderState> build() async {
    return _fetchPages();
  }

  Future<ReaderState> _fetchPages() async {
    try {
      final source = ref.read(mangaSourceProvider(mode.sourceInfo));
      final pages = await source.getPages(mode.episode.id);

      if (pages.isEmpty) {
        return const ReaderState(isLoading: false, error: 'No pages found.');
      }

      return ReaderState(isLoading: false, pages: pages);
    } catch (e) {
      return ReaderState(isLoading: false, error: e.toString());
    }
  }

  Future<void> retry() async {
    state = const AsyncData(ReaderState(isLoading: true));
    state = AsyncData(await _fetchPages());
  }
}

final readerProvider =
    AsyncNotifierProvider.family<ReaderNotifier, ReaderState, ReaderModeOnline>(
      ReaderNotifier.new,
      name: 'readerProvider',
    );
