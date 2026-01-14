import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/services/download_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/repository/downloads_repository.dart';
import 'package:shonenx/features/settings/view_model/download_settings_notifier.dart';
import 'package:shonenx/storage_provider.dart';

part 'downloads_notifier.g.dart';

@immutable
class DownloadsState {
  final List<DownloadItem> downloads;
  final dynamic error;

  const DownloadsState({required this.downloads, this.error});

  DownloadsState copyWith({
    List<DownloadItem>? downloads,
    dynamic error,
    bool clearError = false,
  }) {
    return DownloadsState(
      downloads: downloads ?? this.downloads,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@Riverpod(keepAlive: true)
class DownloadsNotifier extends _$DownloadsNotifier {
  late final DownloadService _service;
  final DownloadsRepository _repository = DownloadsRepository();

  @override
  DownloadsState build() {
    _service = DownloadService(ref);
    _loadDownloads();
    return const DownloadsState(downloads: []);
  }

  Future<void> _loadDownloads() async {
    try {
      await _repository.init();
      final downloads = _repository.getDownloads();
      state = state.copyWith(downloads: downloads);
    } catch (e, st) {
      AppLogger.e("Failed to load downloads", e, st);
      state = state.copyWith(error: e);
    }
  }

  Future<void> addDownload(DownloadItem download) async {
    final settings = ref.read(downloadSettingsProvider);
    String baseDir;

    if (settings.useCustomPath && settings.customDownloadPath != null) {
      baseDir = settings.customDownloadPath!;
    } else {
      final defaultDir = await StorageProvider().getDefaultDirectory();
      if (defaultDir == null) {
        AppLogger.w("Cannot store download: No storage directory");
        return;
      }
      baseDir = defaultDir.path;
    }

    // Sanitize folder names for filesystem safety
    final sanitizedAnime = download.animeTitle.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '',
    );
    final sanitizedEpisode = download.episodeTitle.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '',
    );

    String fullFolder = switch (settings.folderStructure) {
      'Anime/Season/Episode' ||
      'Anime/Episode' => p.join(baseDir, sanitizedAnime, sanitizedEpisode),
      'Anime' => p.join(baseDir, sanitizedAnime),
      _ => baseDir,
    };

    final fileName = p.basename(download.filePath);
    final finalPath = p.join(fullFolder, fileName);
    final finalDownload = download.copyWith(filePath: finalPath);

    if (state.downloads.any((d) => d.filePath == finalDownload.filePath)) {
      AppLogger.w("Download already exists: ${finalDownload.episodeTitle}");
      return;
    }

    state = state.copyWith(downloads: [...state.downloads, finalDownload]);

    try {
      await _repository.saveDownload(finalDownload);
      _service.startDownload(finalDownload);
    } catch (e) {
      setError(e);
    }
  }

  void pauseDownload(DownloadItem item) {
    _service.pauseDownload(item);
  }

  void resumeDownload(DownloadItem item) {
    updateDownloadState(item.copyWith(state: DownloadStatus.downloading));
    _service.resumeDownload(item);
  }

  void deleteDownload(DownloadItem item) {
    _service
        .deleteDownload(item)
        .then((_) {
          _repository.deleteDownload(item.filePath);
          removeDownload(item);
        })
        .onError((error, stackTrace) {
          setError(error);
        });
  }

  void removeDownload(DownloadItem item) {
    state = state.copyWith(
      downloads: state.downloads
          .where((d) => d.filePath != item.filePath)
          .toList(),
    );
  }

  void updateDownloadState(DownloadItem item) {
    AppLogger.d(
      'State update: ${item.episodeTitle} -> ${item.state} '
      '(progress: ${item.progress}/${item.totalSegments ?? item.size})',
    );

    state = state.copyWith(
      downloads: state.downloads
          .map((d) => d.filePath == item.filePath ? item : d)
          .toList(),
    );
    _repository.saveDownload(item);
  }

  void setError(dynamic error) {
    state = state.copyWith(error: error);
  }

  void clearDownloads() {
    state = state.copyWith(downloads: []);
    _repository.clearAll();
  }
}
