import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/core/services/one_dm_service.dart';
import 'package:shonenx/features/downloads/domain/download_repository.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/utils/download_url_helper.dart';
import 'package:shonenx/core/network/stream_server/stream_server.dart';
import 'package:shonenx/core/network/stream_server/hls/hls_stream.dart';

import 'package:byte_me/byte_me.dart' as bm;

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository(ref.watch(databaseProvider));
});

final downloadTasksProvider = StreamProvider<List<DownloadTask>>((ref) {
  return ref.watch(downloadRepositoryProvider).watchAllTasks();
});

final downloadManagerProvider =
    AsyncNotifierProvider<DownloadManagerNotifier, DownloadManagerNotifier>(
      DownloadManagerNotifier.new,
    );

class DownloadManagerNotifier extends AsyncNotifier<DownloadManagerNotifier> {
  late bm.ByteMe _manager;
  final Set<String> _trackedJobs = {};
  final Map<int, int> _lastNotifiedPct = {};
  final Map<int, DateTime> _lastDbWriteTime = {};

  DownloadRepository get repo => ref.read(downloadRepositoryProvider);

  @override
  Future<DownloadManagerNotifier> build() async {
    final prefs = await ref.read(downloadPrefsProvider.future);
    _manager = bm.ByteMe(maxConcurrentDownloads: prefs.concurrentDownloads);

    final unfinished = await repo.getUnfinishedTasks();
    for (final t in unfinished) {
      if (t.status == DownloadStatus.downloading) {
        t.status = DownloadStatus.pending;
        await repo.putTask(t);
      }

      // Auto-resume pending tasks
      if (t.status == DownloadStatus.pending) {
        startDownload(t);
      }
    }
    return this;
  }

  Future<void> startDownload(DownloadTask task) async {
    final prefs = await ref.read(downloadPrefsProvider.future);

    // Unwrap local server/bridge URL to target URL
    final unwrapUrl = DownloadUrlHelper.extractUrl(task.url);
    task.headersMap = DownloadUrlHelper.extractHeadersFromUrl(
      task.url,
      task.headersMap,
    );
    task.url = unwrapUrl;

    if (task.requiresProxy) {
      final server = ref.read(streamServerProvider);
      final hlsUrl = await server.register(
        HlsStream(
          id: task.id.toString(),
          upstreamUrl: task.url,
          headers: task.headersMap,
        ),
      );
      task.url = hlsUrl;
    }

    if (prefs.useOneDM) {
      final success = await OneDMService.instance.download(
        url: task.url,
        fileName: task.fileName,
        headers: Map.fromEntries(
          task.headers.map((header) => header.toMapEntry()),
        ),
      );
      if (success) return;
    }

    if (DownloadUrlHelper.isTorrent(task.url)) {
      throw Exception(
        'Torrent streams cannot be downloaded by the internal download service. Please use 1DM.',
      );
    }

    final isHLS =
        task.isM3u8 ||
        await ref
            .read(httpClientProvider)
            .isHLS(task.url, headers: task.headersMap);

    if (isHLS && !task.isM3u8) {
      task.isM3u8 = true;
    }

    task.status = DownloadStatus.pending;
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();
    await repo.putTask(task);

    final jobId = task.id.toString();
    if (_trackedJobs.contains(jobId)) {
      _manager.resume(jobId);
      return;
    }
    _trackedJobs.add(jobId);

    bm.DownloadTask job;
    if (isHLS) {
      final isBuiltin = prefs.remuxerPreference == RemuxerPreference.builtin;

      final subTracks = task.subtitles
          .map(
            (s) => bm.SubtitleTrack(
              url: s.url,
              language: s.language,
              title: s.label,
              headers: task.headersMap,
            ),
          )
          .toList();

      job = _manager.downloadHls(
        id: jobId,
        url: Uri.parse(task.url),
        savePath: task.savePath,
        maxConcurrentSegments: prefs.concurrentSegments,
        headers: task.headersMap,
        remuxer: isBuiltin
            ? bm.MkvRemuxer(subtitles: subTracks)
            : bm.FfmpegRemuxer(subtitles: subTracks),
        totalSize: task.totalBytes > 0 ? task.totalBytes : null,
      );
    } else {
      job = _manager.download(
        id: jobId,
        url: Uri.parse(task.url),
        savePath: task.savePath,
        headers: task.headersMap,
      );
    }

    _listenToJob(task.id, job);
  }

  void _listenToJob(int dbTaskId, bm.DownloadTask job) {
    final notif = NotificationService.instance;

    job.progressStream.listen((progress) async {
      final now = DateTime.now();
      final lastWrite = _lastDbWriteTime[dbTaskId];

      // Throttle updates (DB read/write & notifications) to once per second,
      // but always process the final 100% completion event.
      if (progress.percent < 1.0 &&
          lastWrite != null &&
          now.difference(lastWrite).inMilliseconds < 1000) {
        return;
      }
      _lastDbWriteTime[dbTaskId] = now;

      final task = await repo.getTaskById(dbTaskId);
      if (task == null) return;

      task.downloadedBytes = progress.receivedBytes;
      task.totalBytes = progress.totalBytes ?? 0;
      task.progress = progress.percent;
      task.speed = progress.formattedSpeed;
      task.updatedAt = now;
      await repo.putTask(task);

      final pct = (progress.percent * 100).toInt();
      final lastNotified = _lastNotifiedPct[dbTaskId] ?? -1;

      // Update notification if the percentage changed
      if (pct > lastNotified) {
        _lastNotifiedPct[dbTaskId] = pct;
        final title = task.fileName.isNotEmpty
            ? task.fileName
            : 'Episode ${task.episodeNumber}';
        await notif.showDownloadProgress(
          id: dbTaskId,
          title: title,
          progress: progress.percent,
        );
      }
    });

    job.statusStream.listen((status) async {
      final task = await repo.getTaskById(dbTaskId);
      if (task == null) return;

      final title = task.fileName.isNotEmpty
          ? task.fileName
          : 'Episode ${task.episodeNumber}';

      switch (status) {
        case bm.DownloadStatus.queued:
          task.status = DownloadStatus.pending;
          break;
        case bm.DownloadStatus.downloading:
          task.status = DownloadStatus.downloading;
          break;
        case bm.DownloadStatus.paused:
          task.status = DownloadStatus.paused;
          await notif.cancelDownloadNotification(dbTaskId);
          break;
        case bm.DownloadStatus.completed:
          task.status = DownloadStatus.completed;
          await notif.showDownloadComplete(id: dbTaskId, title: title);
          await repo.deleteTask(dbTaskId);
          _trackedJobs.remove(job.id);
          _lastNotifiedPct.remove(dbTaskId);
          _lastDbWriteTime.remove(dbTaskId);
          return;
        case bm.DownloadStatus.failed:
          task.status = DownloadStatus.failed;
          await notif.showDownloadFailed(id: dbTaskId, title: title);
          break;
        case bm.DownloadStatus.cancelled:
          task.status = DownloadStatus.canceled;
          await notif.cancelDownloadNotification(dbTaskId);
          break;
      }

      task.updatedAt = DateTime.now();
      await repo.putTask(task);

      if (status == bm.DownloadStatus.completed ||
          status == bm.DownloadStatus.failed ||
          status == bm.DownloadStatus.cancelled) {
        _trackedJobs.remove(job.id);
        _lastNotifiedPct.remove(dbTaskId);
        _lastDbWriteTime.remove(dbTaskId);
      }
    });
  }

  Future<void> pauseDownload(int taskId) async {
    _manager.pause(taskId.toString());
  }

  Future<void> cancelDownload(int taskId) async {
    _manager.cancel(taskId.toString());
    await repo.deleteTask(taskId);
  }
}
