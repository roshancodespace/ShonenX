import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shonenx/core/network/network_config.dart';
import 'package:shonenx/core/network/session_manager.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
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
  final Map<int, StreamSubscription> _statusSubs = {};
  final Map<int, StreamSubscription> _progressSubs = {};
  final Set<int> _cancelledMangaTasks = {};
  final List<int> _mangaQueue = [];
  int _activeMangaDownloads = 0;

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

  /// Queues and starts downloading a manga chapter.
  Future<void> enqueueMangaChapter({
    required UnifiedMedia media,
    required UnifiedEpisode chapter,
    required SourceInfo sourceInfo,
  }) async {
    final prefs = await ref.read(downloadPrefsProvider.future);
    final sanitize = RegExp(r'[\\/:*?"<>|]');
    final mangaTitle = media.title.getPreferedTitle.replaceAll(sanitize, '_');
    final chNum = chapter.number.toString().endsWith('.0')
        ? chapter.number.toInt().toString()
        : chapter.number.toString();

    final baseName = prefs.fileNameFormat == FileNameFormat.titleAndEpisode
        ? '$mangaTitle - Chapter $chNum'
        : 'Chapter $chNum';
    final safeBaseName = baseName.replaceAll(sanitize, '_');

    var targetDir = prefs.mediaRootPath(isManga: true);
    if (prefs.createSubfolders) {
      targetDir = p.join(targetDir, mangaTitle);
    }
    await Directory(targetDir).create(recursive: true);

    final isCbz = prefs.mangaFormat == MangaDownloadFormat.cbz;
    final savePath = isCbz
        ? p.join(targetDir, '$safeBaseName.cbz')
        : p.join(targetDir, safeBaseName);
    final fileName = isCbz ? '$safeBaseName.cbz' : safeBaseName;

    final taskKey = 'manga://${sourceInfo.id}/${media.id}/${chapter.id}';
    final existing = await repo.getTaskByUrl(taskKey);
    final task = existing ?? DownloadTask()
      ..url = taskKey;

    task
      ..isManga = true
      ..mediaId = media.id.toString()
      ..mediaTitle = media.title.getPreferedTitle
      ..episodeNumber = chapter.number.toDouble()
      ..chapterTitle = chapter.title ?? 'Chapter $chNum'
      ..sourceId = sourceInfo.id
      ..mangaFormat = prefs.mangaFormat.name
      ..savePath = savePath
      ..fileName = fileName
      ..status = DownloadStatus.pending
      ..progress = 0.0
      ..downloadedBytes = 0
      ..totalBytes = 0
      ..errorReason = null;

    await repo.putTask(task);
    _enqueueMangaTask(task, sourceInfo: sourceInfo, chapterId: chapter.id);
  }

  void _enqueueMangaTask(
    DownloadTask task, {
    SourceInfo? sourceInfo,
    String? chapterId,
  }) {
    if (_mangaQueue.contains(task.id)) return;
    _mangaQueue.add(task.id);
    _pumpMangaQueue(sourceInfo: sourceInfo, chapterId: chapterId);
  }

  Future<void> _pumpMangaQueue({
    SourceInfo? sourceInfo,
    String? chapterId,
  }) async {
    final prefs = await ref.read(downloadPrefsProvider.future);
    final maxConcurrent = prefs.concurrentDownloads.clamp(1, 5);

    while (_activeMangaDownloads < maxConcurrent && _mangaQueue.isNotEmpty) {
      final nextId = _mangaQueue.removeAt(0);
      final task = await repo.getTaskById(nextId);
      if (task == null ||
          task.status == DownloadStatus.paused ||
          task.status == DownloadStatus.canceled) {
        continue;
      }
      _activeMangaDownloads++;
      unawaited(
        _startMangaDownload(
          task,
          sourceInfo: sourceInfo,
          chapterId: chapterId,
        ).whenComplete(() {
          _activeMangaDownloads = (_activeMangaDownloads - 1).clamp(0, 999);
          _pumpMangaQueue();
        }),
      );
    }
  }

  Future<void> _startMangaDownload(
    DownloadTask task, {
    SourceInfo? sourceInfo,
    String? chapterId,
  }) async {
    final prefs = await ref.read(downloadPrefsProvider.future);
    final notif = NotificationService.instance;
    final dbTaskId = task.id;
    _cancelledMangaTasks.remove(dbTaskId);

    try {
      task.status = DownloadStatus.downloading;
      task.errorReason = null;
      await repo.putTask(task);

      var pageUrls = List<String>.from(task.pageUrls);
      final headers = Map<String, String>.from(task.headersMap);

      if (pageUrls.isEmpty) {
        final effectiveSource =
            sourceInfo ??
            SourceInfo(
              id: task.sourceId,
              name: task.sourceId,
              type: SourceType.extension,
              mediaType: MediaType.MANGA,
            );
        final effectiveChapterId = chapterId ?? task.url.split('/').last;
        final pages = await ref
            .read(mangaSourceProvider(effectiveSource))
            .getPages(effectiveChapterId);
        if (pages.isEmpty) {
          throw Exception('No pages found for chapter.');
        }
        pageUrls = pages.map((e) => e.url).toList();
        for (final page in pages) {
          if (page.headers != null) {
            headers.addAll(page.headers!);
          }
        }
        task.pageUrls = pageUrls;
        task.headersMap = headers;
        await repo.putTask(task);
      }

      final isCbz = task.mangaFormat == MangaDownloadFormat.cbz.name;
      final workDir = Directory(
        isCbz ? '${task.savePath}.tmp' : task.savePath,
      );
      if (!await workDir.exists()) {
        await workDir.create(recursive: true);
      }

      final totalPages = pageUrls.length;
      int completedPages = 0;
      int totalBytes = 0;
      final concurrency = prefs.concurrentMangaPages.clamp(1, 8);
      int nextIndex = 0;
      final sw = Stopwatch()..start();
      DateTime lastDbWrite = DateTime.fromMillisecondsSinceEpoch(0);
      Future<void> dbChain = Future.value();

      Future<void> persistProgress(bool force) {
        final now = DateTime.now();
        if (!force && now.difference(lastDbWrite).inMilliseconds < 400) {
          return Future.value();
        }
        lastDbWrite = now;
        final snapCompleted = completedPages;
        final snapBytes = totalBytes;
        final pct = snapCompleted / totalPages;
        final elapsedSec = sw.elapsedMilliseconds / 1000.0;
        final speedBps = elapsedSec > 0 ? snapBytes / elapsedSec : 0.0;
        final pctInt = (pct * 100).toInt();

        dbChain = dbChain.then((_) async {
          if (_cancelledMangaTasks.contains(dbTaskId)) return;
          final current = await repo.getTaskById(dbTaskId);
          if (current == null || _cancelledMangaTasks.contains(dbTaskId)) return;
          current.downloadedBytes = snapBytes;
          current.progress = pct;
          current.speed =
              '${(speedBps / 1024).toStringAsFixed(0)} KB/s ($snapCompleted/$totalPages)';
          current.updatedAt = DateTime.now();
          await repo.putTask(current);

          if (pctInt > (_lastNotifiedPct[dbTaskId] ?? -1)) {
            _lastNotifiedPct[dbTaskId] = pctInt;
            await notif.showDownloadProgress(
              id: dbTaskId,
              title: task.fileName,
              progress: pct,
            );
          }
        });
        return dbChain;
      }

      Future<http.Response> fetchWithRetry(String url, Map<String, String> reqHeaders) async {
        Object? lastErr;
        for (int attempt = 0; attempt < 3; attempt++) {
          if (_cancelledMangaTasks.contains(dbTaskId)) {
            throw Exception('Cancelled');
          }
          try {
            final resp = await http
                .get(Uri.parse(url), headers: reqHeaders)
                .timeout(const Duration(seconds: 30));
            if (resp.statusCode >= 200 && resp.statusCode < 300) {
              return resp;
            }
            lastErr = Exception('HTTP ${resp.statusCode}');
          } catch (e) {
            lastErr = e;
          }
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
          }
        }
        throw lastErr ?? Exception('Failed to download page');
      }

      Future<void> worker() async {
        while (true) {
          if (_cancelledMangaTasks.contains(dbTaskId)) return;
          final idx = nextIndex++;
          if (idx >= totalPages) return;

          final rawUrl = pageUrls[idx];
          final cleanUrl = rawUrl.split('#').first;
          final ext = _guessImageExtension(cleanUrl);
          final pageName = '${(idx + 1).toString().padLeft(3, '0')}$ext';
          final pageFile = File(p.join(workDir.path, pageName));

          if (await pageFile.exists() && await pageFile.length() > 0) {
            totalBytes += await pageFile.length();
          } else {
            final reqHeaders = _buildPageHeaders(cleanUrl, headers);
            final resp = await fetchWithRetry(cleanUrl, reqHeaders);
            await pageFile.writeAsBytes(resp.bodyBytes, flush: true);
            totalBytes += resp.bodyBytes.length;
          }

          completedPages++;
          await persistProgress(completedPages == totalPages);
        }
      }

      await Future.wait(List.generate(concurrency, (_) => worker()));
      await dbChain;

      if (_cancelledMangaTasks.contains(dbTaskId)) {
        await notif.cancelDownloadNotification(dbTaskId);
        return;
      }

      if (isCbz) {
        final workPath = workDir.path;
        final outPath = task.savePath;
        await Isolate.run(() => _packCbzSync(workPath, outPath));
        if (await workDir.exists()) {
          await workDir.delete(recursive: true);
        }
      }

      await notif.showDownloadComplete(id: dbTaskId, title: task.fileName);
      await repo.deleteTask(dbTaskId);
      _lastNotifiedPct.remove(dbTaskId);
    } catch (e) {
      if (_cancelledMangaTasks.contains(dbTaskId)) return;
      final current = await repo.getTaskById(dbTaskId);
      if (current != null) {
        current.status = DownloadStatus.failed;
        current.errorReason = e.toString();
        await repo.putTask(current);
      }
      await notif.showDownloadFailed(id: dbTaskId, title: task.fileName);
    }
  }

  static Map<String, String> _buildPageHeaders(
    String cleanUrl,
    Map<String, String> baseHeaders,
  ) {
    final sessionManager = SessionManager();
    final cookies = sessionManager.getCookiesSync(cleanUrl);
    final userAgent =
        sessionManager.getUserAgentSync(cleanUrl) ??
        NetworkConfig.globalUserAgent;
    return {
      'User-Agent': userAgent,
      if (cookies.isNotEmpty) 'Cookie': cookies,
      ...NetworkConfig.globalHeaders,
      ...baseHeaders,
    };
  }

  static String _guessImageExtension(String url) {
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.gif')) return '.gif';
    return '.jpg';
  }

  static void _packCbzSync(String sourceDirPath, String cbzOutputPath) {
    final dir = Directory(sourceDirPath);
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    final archive = Archive();
    for (final file in files) {
      final bytes = file.readAsBytesSync();
      archive.addFile(ArchiveFile(p.basename(file.path), bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive);
    File(cbzOutputPath).writeAsBytesSync(zipBytes, flush: true);
  }

  Future<void> startDownload(DownloadTask task) async {
    if (task.isManga) {
      task.status = DownloadStatus.pending;
      task.errorReason = null;
      await repo.putTask(task);
      _enqueueMangaTask(task);
      return;
    }
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
      final subtitleUrls = <String>[];
      final subtitleFileNames = <String>[];
      final usedSubNames = <String>{};

      for (final sub in task.subtitles) {
        if (sub.url.isEmpty) continue;
        final subUrl = DownloadUrlHelper.extractUrl(sub.url);
        var subFileName = DownloadUrlHelper.formatSubtitleFileName(
          videoFileName: task.fileName,
          language: sub.language,
          label: sub.label,
          subtitleUrl: sub.url,
        );

        if (usedSubNames.contains(subFileName)) {
          final lastDot = subFileName.lastIndexOf('.');
          if (lastDot != -1) {
            final namePart = subFileName.substring(0, lastDot);
            final extPart = subFileName.substring(lastDot);
            var counter = 2;
            while (usedSubNames.contains('$namePart-$counter$extPart')) {
              counter++;
            }
            subFileName = '$namePart-$counter$extPart';
          }
        }

        usedSubNames.add(subFileName);
        subtitleUrls.add(subUrl);
        subtitleFileNames.add(subFileName);
      }

      final success = await OneDMService.instance.download(
        url: task.url,
        fileName: task.fileName,
        headers: Map.fromEntries(
          task.headers.map((header) => header.toMapEntry()),
        ),
        subtitleUrls: subtitleUrls,
        subtitleFileNames: subtitleFileNames,
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
    task.errorReason = null;
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

    _progressSubs[dbTaskId]?.cancel();
    _statusSubs[dbTaskId]?.cancel();

    _progressSubs[dbTaskId] = job.progressStream.listen((progress) async {
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

      if (task.status == DownloadStatus.pending) {
        task.status = DownloadStatus.downloading;
        task.errorReason = null;
      }

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

    Future<void> handleStatus(bm.DownloadStatus status) async {
      final task = await repo.getTaskById(dbTaskId);
      if (task == null) return;

      final title = task.fileName.isNotEmpty
          ? task.fileName
          : 'Episode ${task.episodeNumber}';

      switch (status) {
        case bm.DownloadStatus.queued:
          task.status = DownloadStatus.pending;
          task.errorReason = null;
          break;
        case bm.DownloadStatus.downloading:
          task.status = DownloadStatus.downloading;
          task.errorReason = null;
          break;
        case bm.DownloadStatus.paused:
          task.status = DownloadStatus.paused;
          await notif.cancelDownloadNotification(dbTaskId);
          break;
        case bm.DownloadStatus.completed:
          task.status = DownloadStatus.completed;
          task.errorReason = null;
          await notif.showDownloadComplete(id: dbTaskId, title: title);
          await repo.deleteTask(dbTaskId);
          _cleanupJob(dbTaskId, job.id);
          return;
        case bm.DownloadStatus.failed:
          task.status = DownloadStatus.failed;
          task.errorReason = job.error ?? 'Download failed. Tap to retry.';
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
        _cleanupJob(dbTaskId, job.id);
      }
    }

    _statusSubs[dbTaskId] = job.statusStream.listen(handleStatus);

    // If job has already transitioned past queued before subscription, sync status immediately
    if (job.status != bm.DownloadStatus.queued) {
      handleStatus(job.status);
    }
  }

  void _cleanupJob(int dbTaskId, String jobId) {
    _trackedJobs.remove(jobId);
    _lastNotifiedPct.remove(dbTaskId);
    _lastDbWriteTime.remove(dbTaskId);
    _statusSubs.remove(dbTaskId)?.cancel();
    _progressSubs.remove(dbTaskId)?.cancel();
  }

  Future<void> pauseDownload(int taskId) async {
    final task = await repo.getTaskById(taskId);
    if (task != null && task.isManga) {
      _cancelledMangaTasks.add(taskId);
      task.status = DownloadStatus.paused;
      await repo.putTask(task);
      await NotificationService.instance.cancelDownloadNotification(taskId);
      return;
    }
    _manager.pause(taskId.toString());
  }

  Future<void> cancelDownload(int taskId) async {
    final task = await repo.getTaskById(taskId);
    if (task != null && task.isManga) {
      _cancelledMangaTasks.add(taskId);
      await NotificationService.instance.cancelDownloadNotification(taskId);
    } else {
      _manager.cancel(taskId.toString());
    }
    await repo.deleteTask(taskId);
  }
}
