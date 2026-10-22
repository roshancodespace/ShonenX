import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/services/one_dm_service.dart';
import 'package:shonenx/core/utils/device_info.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/core/utils/subtitle_extractor.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/features/downloads/utils/download_url_helper.dart';
import 'package:shonenx/features/history/providers/history_provider.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/permission_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

import 'steps/choose_preference_step.dart';
import 'steps/failed_recovery_step.dart';
import 'steps/queueing_step.dart';
import 'steps/select_episodes_step.dart';

enum BatchStep {
  selectEpisodes,
  choosePreference,
  queueing,
  preferenceFallbackPrompt,
  failedRecovery,
}

class BatchDownloadSheet extends ConsumerStatefulWidget {
  final List<UnifiedEpisode> episodes;
  final double watchedProgress;
  final SourceInfo source;
  final UnifiedMedia media;
  final bool forceOneDM;
  final Set<double>? watchedEpisodeNumbers;

  const BatchDownloadSheet({
    super.key,
    required this.episodes,
    required this.watchedProgress,
    required this.source,
    required this.media,
    this.forceOneDM = false,
    this.watchedEpisodeNumbers,
  });

  static Future<void> show(
    BuildContext context,
    List<UnifiedEpisode> episodes,
    double watchedProgress,
    SourceInfo source,
    UnifiedMedia media, {
    bool forceOneDM = false,
    Set<double>? watchedEpisodeNumbers,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'Batch Download',
      child: BatchDownloadSheet(
        episodes: episodes,
        watchedProgress: watchedProgress,
        source: source,
        media: media,
        forceOneDM: forceOneDM,
        watchedEpisodeNumbers: watchedEpisodeNumbers,
      ),
    );
  }

  @override
  ConsumerState<BatchDownloadSheet> createState() => BatchDownloadSheetState();
}

class BatchDownloadSheetState extends ConsumerState<BatchDownloadSheet> {
  late Set<UnifiedEpisode> selectedEpisodes;
  BatchStep currentStep = BatchStep.selectEpisodes;

  List<UnifiedEpisode> get sortedSelected =>
      selectedEpisodes.toList()..sort((a, b) => a.number.compareTo(b.number));

  UnifiedEpisode? referenceEpisode;
  List<VideoServer>? availableServers;
  String? serversError;
  VideoServer? selectedServer;
  List<VideoStream>? availableStreams;
  bool loadingStreams = false;
  String? streamsError;
  VideoStream? selectedStream;

  List<SubtitleTrack> availableSubtitles = [];
  bool loadingSubtitles = false;
  final Map<String, List<VideoStream>> referenceStreamsCache = {};

  Set<String> selectedSubtitleLabels = {};

  int currentIndex = 0;
  int successCount = 0;
  String currentQueueStatus = '';

  final List<UnifiedEpisode> failedEpisodes = [];
  final Map<UnifiedEpisode, String> failureReasons = {};

  bool isQueueingCancelled = false;
  final List<int> queuedTaskIds = [];

  late final Set<double> watchedEpisodeNumbers;
  late final double effectiveWatchedProgress;

  bool isEpisodeWatched(UnifiedEpisode ep) {
    return watchedEpisodeNumbers.contains(ep.number) ||
        (effectiveWatchedProgress > 0 && ep.number <= effectiveWatchedProgress);
  }

  void _initWatchedInfo() {
    final watchHistoryEntries =
        ref.read(historyForMediaProvider(widget.media.id)).value ?? [];
    final syncThreshold = ref.read(trackingPrefsProvider).syncThreshold;
    final historyWatched = watchHistoryEntries
        .where((e) => e.total > 0 && e.progress >= e.total * syncThreshold)
        .map((e) => e.itemNumber)
        .toSet();

    watchedEpisodeNumbers = {
      ...?widget.watchedEpisodeNumbers,
      ...historyWatched,
    };

    final primaryTracker = ref.read(primaryTrackerProvider);
    final trackingState = ref.read(
      mediaTrackingProvider(TrackingQuery(primaryTracker.type, widget.media)),
    );
    final trackedProgress = trackingState.value?.progress.toDouble() ?? 0.0;

    final maxHistoryEp = watchedEpisodeNumbers.fold<double>(
      0.0,
      (max, epNum) => epNum > max ? epNum : max,
    );

    effectiveWatchedProgress = [
      widget.watchedProgress,
      trackedProgress,
      maxHistoryEp,
    ].reduce((a, b) => a > b ? a : b);
  }

  @override
  void initState() {
    super.initState();
    _initWatchedInfo();
    final sortedEpisodes = widget.episodes.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final unwatched = sortedEpisodes
        .where((e) => !isEpisodeWatched(e))
        .toList();
    if (unwatched.isNotEmpty && unwatched.length <= 12) {
      selectedEpisodes = unwatched.toSet();
    } else if (unwatched.isNotEmpty) {
      selectedEpisodes = unwatched.take(5).toSet();
    } else {
      selectedEpisodes = sortedEpisodes.take(5).toSet();
    }
  }

  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void goToChoosePreference() {
    if (selectedEpisodes.isEmpty) return;
    final firstEp = sortedSelected.first;
    setState(() {
      referenceEpisode = firstEp;
      currentStep = BatchStep.choosePreference;
      availableServers = null;
      serversError = null;
      selectedServer = null;
      availableStreams = null;
      selectedStream = null;
      availableSubtitles = [];
      loadingSubtitles = false;
      selectedSubtitleLabels.clear();
      referenceStreamsCache.clear();
    });
    fetchServersForReference(firstEp);
  }

  Future<void> fetchServersForReference(UnifiedEpisode initialEp) async {
    try {
      final sourceImpl = ref.read(animeSourceProvider(widget.source));
      List<VideoServer>? foundServers;
      UnifiedEpisode? workingEp;

      for (final ep in sortedSelected) {
        try {
          final servers = await sourceImpl.getServers(ep.id);
          if (servers.isNotEmpty) {
            foundServers = servers;
            workingEp = ep;
            break;
          }
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        if (foundServers != null &&
            foundServers.isNotEmpty &&
            workingEp != null) {
          setState(() {
            referenceEpisode = workingEp;
            availableServers = foundServers;
            selectedServer = foundServers!.first;
          });
          fetchStreamsForReference(workingEp, foundServers.first);
        } else {
          setState(() {
            serversError =
                'Could not load servers for any of the selected episodes.';
            availableServers = [];
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => serversError = e.toString());
    }
  }

  Future<void> fetchStreamsForReference(
    UnifiedEpisode ep,
    VideoServer server,
  ) async {
    setState(() {
      loadingStreams = true;
      loadingSubtitles = true;
      streamsError = null;
      availableStreams = null;
      selectedStream = null;
      selectedServer = server;
    });
    try {
      final sourceImpl = ref.read(animeSourceProvider(widget.source));
      final serverKey = '${server.id}_${server.name}_${server.type.name}';

      List<VideoStream> splitStreamsList;
      if (referenceStreamsCache.containsKey(serverKey)) {
        splitStreamsList = referenceStreamsCache[serverKey]!;
      } else {
        final streams = await sourceImpl.getSources(ep.id, server);
        splitStreamsList = <VideoStream>[];
        final httpClient = ref.read(httpClientProvider);

        for (final stream in streams) {
          splitStreamsList.add(stream);
          try {
            final parsedQualities = await httpClient.splitM3U8(
              stream.url,
              headers: stream.headers,
            );
            for (final q in parsedQualities) {
              splitStreamsList.add(
                VideoStream(
                  url: q.url,
                  headers: stream.headers,
                  quality: q.quality,
                  subtitles: stream.subtitles,
                ),
              );
            }
          } catch (_) {}
        }
        referenceStreamsCache[serverKey] = splitStreamsList;
      }

      if (mounted) {
        setState(() {
          availableStreams = splitStreamsList;
          loadingStreams = false;
          if (splitStreamsList.isNotEmpty) {
            selectedStream = splitStreamsList.first;
          }
        });
      }

      final serverStreams = <VideoServer, List<VideoStream>>{
        server: splitStreamsList,
      };

      final otherServers = (availableServers ?? [])
          .where((s) => s.id != server.id || s.type != server.type)
          .toList();

      if (otherServers.isNotEmpty) {
        final streamsList = await Future.wait(
          otherServers.map((s) async {
            final key = '${s.id}_${s.name}_${s.type.name}';
            if (referenceStreamsCache.containsKey(key)) {
              return referenceStreamsCache[key]!;
            }
            try {
              final sStreams = await sourceImpl.getSources(ep.id, s);
              referenceStreamsCache[key] = sStreams;
              return sStreams;
            } catch (_) {
              return <VideoStream>[];
            }
          }),
        );
        for (int i = 0; i < otherServers.length; i++) {
          serverStreams[otherServers[i]] = streamsList[i];
        }
      }

      final extractedSubs = SubtitleExtractor.extractFromServers(serverStreams);

      if (mounted) {
        setState(() {
          availableSubtitles = extractedSubs;
          loadingSubtitles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          streamsError = e.toString();
          loadingStreams = false;
          loadingSubtitles = false;
        });
      }
    }
  }

  Future<void> startQueueLoop({
    bool fromIndexZero = true,
    bool? overrideOneDM,
  }) async {
    if (selectedServer == null || selectedStream == null) return;

    if (fromIndexZero) {
      if (Platform.isAndroid) {
        final permission = await DeviceInfo.isAndroid10OrBelow()
            ? Permission.storage
            : Permission.manageExternalStorage;
        final status = await permission.status;
        if (!status.isGranted) {
          if (!mounted) return;
          final granted = await PermissionSheet.show(
            context,
            permission: permission,
            title: 'Storage Permission',
            description:
                'To download episodes, ShonenX needs access to your device storage.',
            rationale:
                'Used only to save downloaded video files to your chosen folder.',
          );
          if (!granted) return;
        }

        final batteryStatus =
            await Permission.ignoreBatteryOptimizations.status;
        if (!batteryStatus.isGranted) {
          if (!mounted) return;
          await PermissionSheet.show(
            context,
            permission: Permission.ignoreBatteryOptimizations,
            title: 'Background Download Permission',
            description:
                'To keep downloads running when ShonenX is in the background or recent apps, please disable battery optimization.',
            rationale:
                'Android restricts background network and processor tasks to save battery. Disabling optimization ensures downloads are not paused when switching apps.',
          );
        }
      }
      currentIndex = 0;
      successCount = 0;
      failedEpisodes.clear();
      failureReasons.clear();
      isQueueingCancelled = false;
      queuedTaskIds.clear();
    }

    setState(() {
      currentStep = BatchStep.queueing;
    });

    final sorted = sortedSelected;
    final total = sorted.length;
    final prefs = await ref.read(downloadPrefsProvider.future);
    final sourceImpl = ref.read(animeSourceProvider(widget.source));

    final prefServerName = selectedServer?.name;
    final prefServerType = selectedServer?.type;
    final prefQuality = selectedStream?.quality;

    final List<String> oneDmUrls = [];
    final List<String> oneDmFileNames = [];
    Map<String, String>? oneDmHeaders;

    final use1DM = overrideOneDM ?? (widget.forceOneDM || prefs.useOneDM);

    while (currentIndex < total) {
      if (!mounted || currentStep != BatchStep.queueing) break;
      if (isQueueingCancelled) break;

      final ep = sorted[currentIndex];
      final epNumStr = ep.number.toString().contains('.0')
          ? ep.number.toInt().toString()
          : ep.number.toString();

      setState(() {
        currentQueueStatus =
            'Resolving Episode $epNumStr (${currentIndex + 1}/$total)...';
      });

      try {
        final servers = await sourceImpl.getServers(ep.id);
        if (servers.isEmpty) {
          failedEpisodes.add(ep);
          failureReasons[ep] = 'No servers returned';
          currentIndex++;
          continue;
        }

        VideoServer? matchedServer =
            servers
                .where(
                  (s) => s.name == prefServerName && s.type == prefServerType,
                )
                .firstOrNull ??
            servers.where((s) => s.name == prefServerName).firstOrNull ??
            servers.where((s) => s.type == prefServerType).firstOrNull;

        if (matchedServer == null) {
          failedEpisodes.add(ep);
          failureReasons[ep] =
              'Server "$prefServerName" ($prefServerType) not found';
          currentIndex++;
          continue;
        }

        final streams = await sourceImpl.getSources(ep.id, matchedServer);
        if (streams.isEmpty) {
          failedEpisodes.add(ep);
          failureReasons[ep] = 'No video streams returned';
          currentIndex++;
          continue;
        }

        final splitStreamsList = <VideoStream>[];
        final httpClient = ref.read(httpClientProvider);
        for (final stream in streams) {
          splitStreamsList.add(stream);
          try {
            final parsedQualities = await httpClient.splitM3U8(
              stream.url,
              headers: stream.headers,
            );
            for (final q in parsedQualities) {
              splitStreamsList.add(
                VideoStream(
                  url: q.url,
                  headers: stream.headers,
                  quality: q.quality,
                  subtitles: stream.subtitles,
                ),
              );
            }
          } catch (_) {}
        }

        VideoStream? matchedStream =
            splitStreamsList
                .where((s) => s.quality == prefQuality)
                .firstOrNull ??
            splitStreamsList
                .where((s) => s.quality.contains(prefQuality ?? ''))
                .firstOrNull ??
            splitStreamsList.firstOrNull;

        if (matchedStream == null) {
          failedEpisodes.add(ep);
          failureReasons[ep] = 'Stream quality "$prefQuality" not found';
          currentIndex++;
          continue;
        }

        var fileName = prefs.fileNameFormat == FileNameFormat.titleAndEpisode
            ? '${widget.media.title.getPreferedTitle} - Episode $epNumStr.mp4'
            : 'Episode $epNumStr.mp4';
        fileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

        String targetDir = prefs.downloadPath;
        if (prefs.createSubfolders) {
          final animeFolderName = widget.media.title.getPreferedTitle
              .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          targetDir = '$targetDir/$animeFolderName';
        }

        final dir = Directory(targetDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final extractedUrl = DownloadUrlHelper.extractUrl(matchedStream.url);
        final mergedHeaders = DownloadUrlHelper.extractHeadersFromUrl(
          matchedStream.url,
          matchedStream.headers,
        );

        final epServerStreams = <VideoServer, List<VideoStream>>{
          matchedServer: splitStreamsList,
        };
        var epSubtitles = SubtitleExtractor.extractFromServers(epServerStreams);

        if (selectedSubtitleLabels.isNotEmpty && servers.length > 1) {
          final hasAllSubs = selectedSubtitleLabels.every(
            (sel) => epSubtitles.any((sub) => _matchesSubtitle(sub, {sel})),
          );
          if (!hasAllSubs) {
            final otherServers = servers
                .where((s) => s.id != matchedServer.id)
                .toList();
            final streamsList = await Future.wait(
              otherServers.map((s) async {
                try {
                  return await sourceImpl.getSources(ep.id, s);
                } catch (_) {
                  return <VideoStream>[];
                }
              }),
            );
            for (int i = 0; i < otherServers.length; i++) {
              epServerStreams[otherServers[i]] = streamsList[i];
            }
            epSubtitles = SubtitleExtractor.extractFromServers(epServerStreams);
          }
        }

        final matchedSubs = epSubtitles
            .where(
              (sub) =>
                  _matchesSubtitle(sub, selectedSubtitleLabels) &&
                  sub.url.isNotEmpty,
            )
            .toList();

        if (use1DM) {
          oneDmUrls.add(extractedUrl);
          oneDmFileNames.add(fileName);
          oneDmHeaders ??= mergedHeaders;

          final usedSubNames = <String>{};
          for (final sub in matchedSubs) {
            final subUrl = DownloadUrlHelper.extractUrl(sub.url);
            var subFileName = DownloadUrlHelper.formatSubtitleFileName(
              videoFileName: fileName,
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
            oneDmUrls.add(subUrl);
            oneDmFileNames.add(subFileName);
          }
        } else {
          final downloadUrl = DownloadUrlHelper.extractDownloadUrl(
            matchedStream.url,
          );
          if (downloadUrl == null ||
              DownloadUrlHelper.isTorrent(matchedStream.url)) {
            failedEpisodes.add(ep);
            failureReasons[ep] = 'Torrents require 1DM downloader';
            currentIndex++;
            continue;
          }

          final task = DownloadTask()
            ..url = downloadUrl
            ..mediaId = widget.media.id
            ..headersMap = mergedHeaders
            ..episodeNumber = ep.number
            ..savePath = '$targetDir/$fileName'
            ..fileName = fileName
            ..requiresProxy = matchedStream.requiresProxy
            ..totalBytes = DownloadUrlHelper.parseSizeToBytes(
              matchedStream.size,
            )
            ..subtitles = matchedSubs
                .map(
                  (s) => DownloadSubtitle.create(
                    url: s.url,
                    language: s.language,
                    label: s.label ?? s.language,
                  ),
                )
                .toList();

          await ref.read(downloadManagerProvider.notifier).startDownload(task);
          queuedTaskIds.add(task.id);
        }
        successCount++;
        currentIndex++;
      } catch (e) {
        failedEpisodes.add(ep);
        failureReasons[ep] = e.toString().replaceAll('Exception: ', '');
        currentIndex++;
      }
    }

    if (isQueueingCancelled) return;

    if (use1DM && oneDmUrls.isNotEmpty) {
      await OneDMService.instance.downloadBatch(
        urls: oneDmUrls,
        fileNames: oneDmFileNames,
        headers: oneDmHeaders,
      );
    }

    if (mounted && currentIndex >= total) {
      if (failedEpisodes.isNotEmpty) {
        setState(() {
          currentStep = BatchStep.failedRecovery;
        });
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully queued $successCount of $total episodes for download!',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQueueing = currentStep == BatchStep.queueing;
    return PopScope(
      canPop: !isQueueing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isQueueing) {
          showCancelDialog(context);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStep(),
      ),
    );
  }

  void showCancelDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      title: 'Cancel Batch Download?',
      child: const Text(
        'Do you want to stop queueing the remaining episodes? You can also optionally cancel the downloads that have already been started in this batch.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
        TextButton(
          onPressed: () {
            isQueueingCancelled = true;
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: const Text('Stop Only'),
        ),
        FilledButton(
          onPressed: () {
            isQueueingCancelled = true;
            for (final id in queuedTaskIds) {
              ref.read(downloadManagerProvider.notifier).cancelDownload(id);
            }
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Stop & Cancel Downloads'),
        ),
      ],
    );
  }

  bool _matchesSubtitle(SubtitleTrack sub, Set<String> selected) {
    if (selected.isEmpty) return false;
    final display = SubtitleExtractor.formatDisplayTitle(sub).toLowerCase();
    final sLabel = (sub.label ?? '').toLowerCase();
    final lang = sub.language.toLowerCase();

    for (final sel in selected) {
      final s = sel.toLowerCase();
      if (s == display || s == sLabel || s == lang) return true;
      if (display.contains(s) || s.contains(display)) return true;
      if (sLabel.isNotEmpty && (sLabel.contains(s) || s.contains(sLabel))) {
        return true;
      }
      if (lang.isNotEmpty && (lang.contains(s) || s.contains(lang))) {
        return true;
      }
    }
    return false;
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case BatchStep.selectEpisodes:
        return SelectEpisodesStep(state: this);
      case BatchStep.choosePreference:
      case BatchStep.preferenceFallbackPrompt:
        return ChoosePreferenceStep(state: this);
      case BatchStep.queueing:
        return QueueingStep(state: this);
      case BatchStep.failedRecovery:
        return FailedRecoveryStep(state: this);
    }
  }
}
