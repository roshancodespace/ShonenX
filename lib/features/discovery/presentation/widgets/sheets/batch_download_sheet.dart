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
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/permission_sheet.dart';

enum _BatchStep {
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

  const BatchDownloadSheet({
    super.key,
    required this.episodes,
    required this.watchedProgress,
    required this.source,
    required this.media,
  });

  static Future<void> show(
    BuildContext context,
    List<UnifiedEpisode> episodes,
    double watchedProgress,
    SourceInfo source,
    UnifiedMedia media,
  ) {
    return AppBottomSheet.show(
      context: context,
      title: 'Batch Download',
      child: BatchDownloadSheet(
        episodes: episodes,
        watchedProgress: watchedProgress,
        source: source,
        media: media,
      ),
    );
  }

  @override
  ConsumerState<BatchDownloadSheet> createState() => _BatchDownloadSheetState();
}

class _BatchDownloadSheetState extends ConsumerState<BatchDownloadSheet> {
  late Set<UnifiedEpisode> _selectedEpisodes;
  _BatchStep _currentStep = _BatchStep.selectEpisodes;

  List<UnifiedEpisode> get _sortedSelected =>
      _selectedEpisodes.toList()..sort((a, b) => a.number.compareTo(b.number));

  UnifiedEpisode? _referenceEpisode;
  List<VideoServer>? _availableServers;
  String? _serversError;
  VideoServer? _selectedServer;
  List<VideoStream>? _availableStreams;
  bool _loadingStreams = false;
  String? _streamsError;
  VideoStream? _selectedStream;

  int _currentIndex = 0;
  int _successCount = 0;
  String _currentQueueStatus = '';

  final List<UnifiedEpisode> _failedEpisodes = [];
  final Map<UnifiedEpisode, String> _failureReasons = {};

  @override
  void initState() {
    super.initState();
    final unwatched = widget.episodes
        .where((e) => e.number > widget.watchedProgress)
        .toList();
    if (unwatched.isNotEmpty && unwatched.length <= 12) {
      _selectedEpisodes = unwatched.toSet();
    } else if (unwatched.isNotEmpty) {
      _selectedEpisodes = unwatched.take(5).toSet();
    } else {
      _selectedEpisodes = widget.episodes.take(5).toSet();
    }
  }

  void _selectAll() {
    setState(() => _selectedEpisodes = widget.episodes.toSet());
  }

  void _selectUnwatched() {
    setState(() {
      _selectedEpisodes = widget.episodes
          .where((e) => e.number > widget.watchedProgress)
          .toSet();
    });
  }

  void _selectNext(int count) {
    final unwatched = widget.episodes
        .where((e) => e.number > widget.watchedProgress)
        .toList();
    final list = unwatched.isNotEmpty ? unwatched : widget.episodes;
    setState(() {
      _selectedEpisodes = list.take(count).toSet();
    });
  }

  void _showRangeDialog() {
    final sorted = widget.episodes.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    if (sorted.isEmpty) return;

    final unwatched = sorted.where((e) => e.number > widget.watchedProgress);
    final initialStart = unwatched.isNotEmpty
        ? unwatched.first.number
        : sorted.first.number;
    final initialEnd = sorted.last.number;

    final startCtrl = TextEditingController(
      text: initialStart.toString().contains('.0')
          ? initialStart.toInt().toString()
          : initialStart.toString(),
    );
    final endCtrl = TextEditingController(
      text: initialEnd.toString().contains('.0')
          ? initialEnd.toInt().toString()
          : initialEnd.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Episode Range',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter start and end episode numbers (available: ${sorted.first.number} to ${sorted.last.number}):',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'From Episode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '—',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'To Episode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final start =
                    double.tryParse(startCtrl.text.trim()) ?? initialStart;
                final end = double.tryParse(endCtrl.text.trim()) ?? initialEnd;
                final minNum = start <= end ? start : end;
                final maxNum = start <= end ? end : start;

                final matched = sorted
                    .where((e) => e.number >= minNum && e.number <= maxNum)
                    .toSet();
                setState(() {
                  _selectedEpisodes = matched;
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply Range'),
            ),
          ],
        );
      },
    );
  }

  void _clearSelection() {
    setState(() => _selectedEpisodes.clear());
  }

  void _goToChoosePreference() {
    if (_selectedEpisodes.isEmpty) return;
    final firstEp = _sortedSelected.first;
    setState(() {
      _referenceEpisode = firstEp;
      _currentStep = _BatchStep.choosePreference;
      _availableServers = null;
      _serversError = null;
      _selectedServer = null;
      _availableStreams = null;
      _selectedStream = null;
    });
    _fetchServersForReference(firstEp);
  }

  Future<void> _fetchServersForReference(UnifiedEpisode initialEp) async {
    try {
      final sourceImpl = ref.read(animeSourceProvider(widget.source));
      List<VideoServer>? foundServers;
      UnifiedEpisode? workingEp;

      // Try the initial reference episode first, then fall back across other selected episodes
      for (final ep in _sortedSelected) {
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
            _referenceEpisode = workingEp;
            _availableServers = foundServers;
            _selectedServer = foundServers!.first;
          });
          _fetchStreamsForReference(workingEp, foundServers.first);
        } else {
          setState(() {
            _serversError =
                'Could not load servers for any of the selected episodes.';
            _availableServers = [];
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _serversError = e.toString());
    }
  }

  Future<void> _fetchStreamsForReference(
    UnifiedEpisode ep,
    VideoServer server,
  ) async {
    setState(() {
      _loadingStreams = true;
      _streamsError = null;
      _availableStreams = null;
      _selectedStream = null;
      _selectedServer = server;
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
          _availableStreams = splitStreamsList;
          _loadingStreams = false;
          if (splitStreamsList.isNotEmpty) {
            _selectedStream = splitStreamsList.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _streamsError = e.toString();
          _loadingStreams = false;
        });
      }
    }
  }

  Future<void> _startQueueLoop({bool fromIndexZero = true}) async {
    if (_selectedServer == null || _selectedStream == null) return;

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
      _currentIndex = 0;
      _successCount = 0;
      _failedEpisodes.clear();
      _failureReasons.clear();
    }

    setState(() {
      _currentStep = _BatchStep.queueing;
    });

    final sorted = _sortedSelected;
    final total = sorted.length;
    final prefs = await ref.read(downloadPrefsProvider.future);
    final sourceImpl = ref.read(animeSourceProvider(widget.source));

    final prefServerName = _selectedServer?.name;
    final prefServerType = _selectedServer?.type;
    final prefQuality = _selectedStream?.quality;

    final List<String> oneDmUrls = [];
    final List<String> oneDmFileNames = [];
    Map<String, String>? oneDmHeaders;

    while (_currentIndex < total) {
      if (!mounted || _currentStep != _BatchStep.queueing) break;
      final ep = sorted[_currentIndex];
      final epNumStr = ep.number.toString().contains('.0')
          ? ep.number.toInt().toString()
          : ep.number.toString();

      setState(() {
        _currentQueueStatus =
            'Resolving Episode $epNumStr (${_currentIndex + 1}/$total)...';
      });

      try {
        final servers = await sourceImpl.getServers(ep.id);
        if (servers.isEmpty) {
          _failedEpisodes.add(ep);
          _failureReasons[ep] = 'No servers returned';
          _currentIndex++;
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
          _failedEpisodes.add(ep);
          _failureReasons[ep] =
              'Server "$prefServerName" ($prefServerType) not found';
          _currentIndex++;
          continue;
        }

        final streams = await sourceImpl.getSources(ep.id, matchedServer);
        if (streams.isEmpty) {
          _failedEpisodes.add(ep);
          _failureReasons[ep] = 'No video streams returned';
          _currentIndex++;
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
          _failedEpisodes.add(ep);
          _failureReasons[ep] = 'Stream quality "$prefQuality" not found';
          _currentIndex++;
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

        if (prefs.useOneDM) {
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
        }
        _successCount++;
        _currentIndex++;
      } catch (e) {
        _failedEpisodes.add(ep);
        _failureReasons[ep] = e.toString().replaceAll('Exception: ', '');
        _currentIndex++;
      }
    }

    if (prefs.useOneDM && oneDmUrls.isNotEmpty) {
      await OneDMService.instance.downloadBatch(
        urls: oneDmUrls,
        fileNames: oneDmFileNames,
        headers: oneDmHeaders,
      );
    }

    if (mounted && _currentIndex >= total) {
      if (_failedEpisodes.isNotEmpty) {
        setState(() {
          _currentStep = _BatchStep.failedRecovery;
        });
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully queued $_successCount of $total episodes for download!',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    switch (_currentStep) {
      case _BatchStep.queueing:
        return _buildQueueingState(cs, textTheme);
      case _BatchStep.choosePreference:
      case _BatchStep.preferenceFallbackPrompt:
        return _buildPreferenceState(cs, textTheme);
      case _BatchStep.failedRecovery:
        return _buildFailedRecoveryState(cs, textTheme);
      case _BatchStep.selectEpisodes:
        return _buildSelectState(cs, textTheme);
    }
  }

  Widget _buildFailedRecoveryState(ColorScheme cs, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: cs.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_successCount episodes queued • ${_failedEpisodes.length} failed',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Would you like to choose a different server or quality for the failed episodes, or continue?',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'FAILED EPISODES',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: cs.error,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _failedEpisodes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ep = _failedEpisodes[index];
              final epNumStr = ep.number.toString().contains('.0')
                  ? ep.number.toInt().toString()
                  : ep.number.toString();
              final reason = _failureReasons[ep] ?? 'Unknown error';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ep $epNumStr',
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ep.title?.isNotEmpty == true
                                ? '${ep.title}'
                                : 'Episode $epNumStr',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            reason,
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.error.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_successCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Queued $_successCount episodes for download.',
                      ),
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedEpisodes = _failedEpisodes.toSet();
                    _failedEpisodes.clear();
                    _failureReasons.clear();
                  });
                  _goToChoosePreference();
                },
                icon: const Icon(
                  Icons.settings_backup_restore_rounded,
                  size: 18,
                ),
                label: Text(
                  'Re-fetch (${_failedEpisodes.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQueueingState(ColorScheme cs, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: _sortedSelected.isNotEmpty
                  ? _currentIndex / _sortedSelected.length
                  : null,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentQueueStatus,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Resolving download links using your server preference...',
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceState(ColorScheme cs, TextTheme textTheme) {
    final isFallback = _currentStep == _BatchStep.preferenceFallbackPrompt;
    final epNumStr = _referenceEpisode?.number.toString().contains('.0') == true
        ? _referenceEpisode?.number.toInt().toString()
        : _referenceEpisode?.number.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isFallback
                ? cs.errorContainer.withValues(alpha: 0.35)
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                isFallback
                    ? Icons.warning_amber_rounded
                    : Icons.auto_awesome_rounded,
                color: isFallback ? cs.error : cs.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFallback
                          ? 'Preference Missing for Episode $epNumStr'
                          : 'Template Reference: Episode $epNumStr',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isFallback ? cs.error : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFallback
                          ? 'Please choose a new server & quality for the remaining ${_sortedSelected.length - _currentIndex} episodes.'
                          : 'Select your preferred server and quality for all ${_selectedEpisodes.length} selected episodes.',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SELECT SERVER',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 10),
        if (_serversError != null)
          Text(
            'Error loading servers: $_serversError',
            style: TextStyle(color: cs.error),
          )
        else if (_availableServers == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_availableServers!.isEmpty)
          const Text('No servers available.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableServers!.map((server) {
              final isSelected = _selectedServer == server;
              final isDub = server.type == ServerType.dub;
              return ChoiceChip(
                label: Text(
                  '${server.name} • ${isDub ? 'DUB' : 'SUB'}',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    _fetchStreamsForReference(_referenceEpisode!, server);
                  }
                },
                selectedColor: cs.primaryContainer,
                backgroundColor: cs.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? cs.primary : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        Text(
          'SELECT VIDEO QUALITY',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 10),
        if (_loadingStreams)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_streamsError != null)
          Text(
            'Error loading qualities: $_streamsError',
            style: TextStyle(color: cs.error),
          )
        else if (_availableStreams == null || _availableStreams!.isEmpty)
          Text(
            'No stream links found for this server.',
            style: TextStyle(color: cs.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStreams!.map((stream) {
              final isSelected = _selectedStream == stream;
              return ChoiceChip(
                label: Text(
                  stream.quality,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStream = stream);
                  }
                },
                selectedColor: cs.primaryContainer,
                backgroundColor: cs.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? cs.primary : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 28),
        Row(
          children: [
            if (!isFallback) ...[
              OutlinedButton(
                onPressed: () =>
                    setState(() => _currentStep = _BatchStep.selectEpisodes),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: (_selectedServer == null || _selectedStream == null)
                    ? null
                    : () => _startQueueLoop(fromIndexZero: !isFallback),
                icon: Icon(
                  isFallback
                      ? Icons.play_arrow_rounded
                      : Icons.download_rounded,
                ),
                label: Text(
                  isFallback
                      ? 'Resume Downloading'
                      : 'Start Batch Download (${_selectedEpisodes.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectState(ColorScheme cs, TextTheme textTheme) {
    final sortedEpisodes = widget.episodes.toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetPill('Select All', _selectAll, cs),
              const SizedBox(width: 8),
              _buildPresetPill('Unwatched', _selectUnwatched, cs),
              const SizedBox(width: 8),
              _buildPresetPill('Range', _showRangeDialog, cs),
              const SizedBox(width: 8),
              _buildPresetPill('Next 5', () => _selectNext(5), cs),
              const SizedBox(width: 8),
              _buildPresetPill('Next 10', () => _selectNext(10), cs),
              const SizedBox(width: 8),
              _buildPresetPill('Clear', _clearSelection, cs),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Selected Episodes',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_selectedEpisodes.length} / ${widget.episodes.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: sortedEpisodes.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              final ep = sortedEpisodes[index];
              final isSelected = _selectedEpisodes.contains(ep);
              final isWatched = ep.number <= widget.watchedProgress;
              final epNumStr = ep.number.toString().contains('.0')
                  ? ep.number.toInt().toString()
                  : ep.number.toString();

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedEpisodes.remove(ep);
                    } else {
                      _selectedEpisodes.add(ep);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedEpisodes.add(ep);
                            } else {
                              _selectedEpisodes.remove(ep);
                            }
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ep.title?.isNotEmpty == true
                                  ? '${ep.title}'
                                  : 'Episode $epNumStr',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Episode $epNumStr',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                if (isWatched) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Watched',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: cs.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _selectedEpisodes.isEmpty ? null : _goToChoosePreference,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(
            'Configure Quality & Server (${_selectedEpisodes.length})',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetPill(String label, VoidCallback onTap, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
