import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/services/one_dm_service.dart';
import 'package:shonenx/core/utils/device_info.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
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

  const BatchDownloadSheet({
    super.key,
    required this.episodes,
    required this.watchedProgress,
    required this.source,
    required this.media,
    this.forceOneDM = false,
  });

  static Future<void> show(
    BuildContext context,
    List<UnifiedEpisode> episodes,
    double watchedProgress,
    SourceInfo source,
    UnifiedMedia media, {
    bool forceOneDM = false,
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

  int currentIndex = 0;
  int successCount = 0;
  String currentQueueStatus = '';

  final List<UnifiedEpisode> failedEpisodes = [];
  final Map<UnifiedEpisode, String> failureReasons = {};

  bool isQueueingCancelled = false;
  final List<int> queuedTaskIds = [];

  @override
  void initState() {
    super.initState();
    final unwatched = widget.episodes
        .where((e) => e.number > widget.watchedProgress)
        .toList();
    if (unwatched.isNotEmpty && unwatched.length <= 12) {
      selectedEpisodes = unwatched.toSet();
    } else if (unwatched.isNotEmpty) {
      selectedEpisodes = unwatched.take(5).toSet();
    } else {
      selectedEpisodes = widget.episodes.take(5).toSet();
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
      streamsError = null;
      availableStreams = null;
      selectedStream = null;
      selectedServer = server;
    });
    try {
      final sourceImpl = ref.read(animeSourceProvider(widget.source));
      final streams = await sourceImpl.getSources(ep.id, server);

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

      if (mounted) {
        setState(() {
          availableStreams = splitStreamsList;
          loadingStreams = false;
          if (splitStreamsList.isNotEmpty) {
            selectedStream = splitStreamsList.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          streamsError = e.toString();
          loadingStreams = false;
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
            ? '${widget.media.title.availableTitle} - Episode $epNumStr.mp4'
            : 'Episode $epNumStr.mp4';
        fileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

        String targetDir = prefs.downloadPath;
        if (prefs.createSubfolders) {
          final animeFolderName = widget.media.title.availableTitle.replaceAll(
            RegExp(r'[\\/:*?"<>|]'),
            '_',
          );
          targetDir = '$targetDir/$animeFolderName';
        }

        final dir = Directory(targetDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        if (use1DM) {
          oneDmUrls.add(matchedStream.url);
          oneDmFileNames.add(fileName);
          oneDmHeaders ??= matchedStream.headers;
        } else {
          final task = DownloadTask()
            ..url = matchedStream.url
            ..mediaId = widget.media.id
            ..headersMap = matchedStream.headers
            ..episodeNumber = ep.number
            ..savePath = '$targetDir/$fileName'
            ..fileName = fileName;

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
