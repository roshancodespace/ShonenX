import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/download_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/repository/downloads_repository.dart';

class DownloadsState {
  final List<DownloadItem> downloads;
  final bool hasError;

  DownloadsState({
    required this.downloads,
    required this.hasError,
  });

  DownloadsState copyWith({
    List<DownloadItem>? downloads,
    bool? hasError,
  }) {
    return DownloadsState(
      downloads: downloads ?? this.downloads,
      hasError: hasError ?? this.hasError,
    );
  }
}

class DownloadNotifier extends StateNotifier<DownloadsState> {
  final DownloadService _service;
  final DownloadsRepository _repository;

  DownloadNotifier(this._service, this._repository)
      : super(DownloadsState(downloads: [], hasError: false)) {
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      await _repository.init();
      final downloads = _repository.getDownloads();
      state = state.copyWith(downloads: downloads);
    } catch (e, st) {
      AppLogger.e("Failed to load downloads", e, st);
      state = state.copyWith(hasError: true);
    }
  }

  void addDownload(DownloadItem download) {
    state = state.copyWith(
      downloads: [...state.downloads, download],
    );
    _repository.saveDownload(download);
    _service.downloadFile(download);
  }

  void pauseDownload(DownloadItem item) {
    final updatedItem = item.copyWith(state: DownloadStatus.paused);
    updateProgress(updatedItem);
    _service.pauseDownload(updatedItem);
  }

  void resumeDownload(DownloadItem item) {
    final updatedItem = item.copyWith(state: DownloadStatus.downloading);
    updateProgress(updatedItem);
    _service.resumeDownload(updatedItem);
  }

  void deleteDownload(DownloadItem item) {
    _service.deleteDownload(item);
    _repository.deleteDownload(item.filePath);
    removeDownload(item);
  }

  void removeDownload(DownloadItem item) {
    state = state.copyWith(
      downloads:
          state.downloads.where((d) => d.filePath != item.filePath).toList(),
    );
  }

  void updateProgress(DownloadItem item) {
    if (item.state == DownloadStatus.paused ||
        item.state == DownloadStatus.downloaded ||
        item.state == DownloadStatus.error) {
      AppLogger.w(item.toString());
    }
    state = state.copyWith(
      downloads: state.downloads
          .map((d) => d.filePath == item.filePath ? item : d)
          .toList(),
    );
    _repository.saveDownload(item);
  }

  void setError(bool error) {
    state = state.copyWith(hasError: error);
  }

  void clearDownloads() {
    state = state.copyWith(downloads: []);
    _repository.clearAll();
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadNotifier, DownloadsState>((ref) {
  return DownloadNotifier(DownloadService(ref), DownloadsRepository());
});
