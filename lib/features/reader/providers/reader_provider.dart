import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/features/history/providers/history_provider.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/shared/providers/security_prefs_provider.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class ReaderState {
  final ReaderMode mode;
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
    ReaderMode? mode,
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
  late final ReaderMode arg;

  ReaderNotifier(this.arg);

  @override
  ReaderState build() {
    final startPage = switch (arg) {
      ReaderModeOnline(:final startPosition) =>
        startPosition == -1 ? 0 : (startPosition > 0 ? startPosition - 1 : 0),
      ReaderModeOffline() => 0,
    };

    Future.microtask(() => _fetchPages(arg));

    return ReaderState(
      mode: arg,
      currentPage: startPage,
      totalPages: 0,
      showOverlay: false,
    );
  }

  Future<void> _fetchPages(ReaderMode mode) async {
    state = state.copyWith(pages: const AsyncValue.loading());
    try {
      if (mode is ReaderModeOffline) {
        final pageList = await _loadOfflinePages(mode.filePath);
        if (pageList.isEmpty) {
          state = state.copyWith(
            pages: AsyncValue.error(
              Exception('No readable pages found in ${mode.filePath}.'),
              StackTrace.current,
            ),
          );
          return;
        }
        state = state.copyWith(
          pages: AsyncValue.data(pageList),
          totalPages: pageList.length,
          currentPage: 0,
        );
        return;
      }

      final online = mode as ReaderModeOnline;
      final source = ref.read(mangaSourceProvider(online.sourceInfo));
      final pageList = await source.getPages(online.episode.id);

      if (pageList.isEmpty) {
        state = state.copyWith(
          pages: AsyncValue.error(
            Exception('No pages found for this chapter.'),
            StackTrace.current,
          ),
        );
        return;
      }

      final startPage = online.startPosition == -1
          ? pageList.length - 1
          : (online.startPosition > 0 ? online.startPosition - 1 : 0).clamp(
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

  static bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  static Future<List<ChapterPage>> _loadOfflinePages(String path) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.directory) {
      final files = Directory(path)
          .listSync()
          .whereType<File>()
          .where((f) => _isImagePath(f.path))
          .toList()
        ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
      return files.map((f) => ChapterPage(url: f.path)).toList();
    }

    if (type == FileSystemEntityType.file &&
        path.toLowerCase().endsWith('.cbz')) {
      final entries = await Isolate.run(() {
        final bytes = File(path).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        final imageFiles = archive
            .where((e) => e.isFile && _isImagePath(e.name))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return imageFiles
            .map((e) => (name: e.name, data: Uint8List.fromList(e.content)))
            .toList();
      });
      return entries
          .map((e) => ChapterPage(url: e.name, bytes: e.data))
          .toList();
    }

    return const [];
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
    final mode = arg;
    if (mode is! ReaderModeOnline) return;
    if (total == 0) return;
    if (ref.read(securityPrefsProvider).incognitoMode) return;
    final savedPageNumber = pageIndex + 1;

    final entry = HistoryEntry()
      ..mediaType = MediaType.MANGA.id
      ..itemNumber = mode.episode.number
      ..mediaId = mode.media.id
      ..mediaIdMal = mode.media.idMal
      ..externalIds = mode.media.externalIds
      ..mediaTitle = mode.media.title.getPreferedTitle
      ..cover = mode.media.cover
      ..banner = mode.media.banner
      ..progress = savedPageNumber
      ..total = total
      ..sourceId = mode.sourceInfo.id
      ..sourceName = mode.sourceInfo.name
      ..providerId = mode.media.providerId != mode.media.id
          ? mode.media.providerId
          : null
      ..lastUpdated = DateTime.now();

    ref.read(historyRepositoryProvider).saveProgress(entry);
    ref
        .read(syncEngineProvider)
        .processReading(
          media: mode.media,
          chapterNumber: mode.episode.number,
          positionPage: savedPageNumber,
          totalPages: total,
        );
  }
}

final readerProvider = NotifierProvider.autoDispose
    .family<ReaderNotifier, ReaderState, ReaderMode>(
      ReaderNotifier.new,
      name: 'readerProvider',
    );
