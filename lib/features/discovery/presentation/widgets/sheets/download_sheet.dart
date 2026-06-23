import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shonenx/core/network/http_client.dart';
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

class DownloadSheet extends ConsumerStatefulWidget {
  final UnifiedEpisode episode;
  final SourceInfo source;
  final UnifiedMedia media;

  const DownloadSheet({
    super.key,
    required this.episode,
    required this.source,
    required this.media,
  });

  static Future<void> show(
    BuildContext context,
    UnifiedEpisode episode,
    SourceInfo source,
    UnifiedMedia media,
  ) {
    return AppBottomSheet.show(
      context: context,
      title:
          'Download Episode ${episode.number.toString().contains('.0') ? episode.number.toInt() : episode.number}',
      child: DownloadSheet(episode: episode, source: source, media: media),
    );
  }

  @override
  ConsumerState<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends ConsumerState<DownloadSheet> {
  List<VideoServer>? _servers;
  String? _error;

  final Map<String, List<VideoStream>> _streamsCache = {};
  final Map<String, String> _streamErrors = {};
  final Set<String> _loadingStreams = {};

  @override
  void initState() {
    super.initState();
    if (widget.media.type == MediaType.MANGA) {
      _error = 'Manga downloading is not supported yet.';
      return;
    }
    _loadServers();
  }

  Future<void> _loadServers() async {
    try {
      final servers = await ref
          .read(animeSourceProvider(widget.source))
          .getServers(widget.episode.id);
      if (mounted) setState(() => _servers = servers);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  String _serverKey(VideoServer s) => '${s.id}_${s.name}_${s.type.name}';

  Future<void> _loadStreams(VideoServer server) async {
    final key = _serverKey(server);
    if (_streamsCache.containsKey(key) || _loadingStreams.contains(key)) return;

    setState(() {
      _loadingStreams.add(key);
      _streamErrors.remove(key);
    });

    try {
      final streams = await ref
          .read(animeSourceProvider(widget.source))
          .getSources(widget.episode.id, server);

      final splitStreamsList = <VideoStream>[];
      final httpClient = ref.read(httpClientProvider);

      for (final stream in streams) {
        splitStreamsList.add(stream); // Keep default Auto/Master first

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
        } catch (_) {
          // Fall back gracefully if parsing fails
        }
      }

      if (mounted) {
        setState(() {
          _streamsCache[key] = splitStreamsList;
          _loadingStreams.remove(key);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _streamErrors[key] = e.toString();
          _loadingStreams.remove(key);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadServers);
    }
    if (_servers == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_servers!.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No servers available.')),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_servers!.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const Divider(height: 1, indent: 20, endIndent: 20);
          }

          final i = index ~/ 2;
          final server = _servers![i];
          final key = _serverKey(server);

          return _ServerTile(
            server: server,
            streams: _streamsCache[key],
            isLoading: _loadingStreams.contains(key),
            error: _streamErrors[key],
            onExpand: () => _loadStreams(server),
            onRetry: () => _loadStreams(server),
            onDownload: (stream) => _startDownload(stream, server),
          );
        }),
      ),
    );
  }

  Future<void> _startDownload(VideoStream stream, VideoServer server) async {
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

        if (!granted) {
          return;
        }
      }
    }

    final prefs = await ref.read(downloadPrefsProvider.future);
    final epNum = widget.episode.number.toString().contains('.0')
        ? widget.episode.number.toInt().toString()
        : widget.episode.number.toString();

    var fileName = prefs.fileNameFormat == FileNameFormat.titleAndEpisode
        ? '${widget.media.title.availableTitle} - Episode $epNum.mp4'
        : 'Episode $epNum.mp4';
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
      try {
        await dir.create(recursive: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create download folder: $e')),
          );
        }
        return;
      }
    }

    final task = DownloadTask()
      ..url = stream.url
      ..mediaId = widget.media.id
      ..headersMap = stream.headers
      ..episodeNumber = widget.episode.number
      ..savePath = '$targetDir/$fileName'
      ..fileName = fileName;

    await ref.read(downloadManagerProvider.notifier).startDownload(task);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download started')));
      Navigator.of(context).pop();
    }
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.streams,
    required this.isLoading,
    required this.error,
    required this.onExpand,
    required this.onRetry,
    required this.onDownload,
  });

  final VideoServer server;
  final List<VideoStream>? streams;
  final bool isLoading;
  final String? error;
  final VoidCallback onExpand;
  final VoidCallback onRetry;
  final void Function(VideoStream) onDownload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDub = server.type == ServerType.dub;

    final subtitle = streams != null
        ? '${streams!.length} streams'
        : 'Tap to load streams';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        onExpansionChanged: (expanded) {
          if (expanded) onExpand();
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: cs.secondaryContainer,
          child: Icon(
            Icons.play_circle_outline_rounded,
            size: 20,
            color: cs.onSecondaryContainer,
          ),
        ),
        title: Text(
          '${server.id.length <= 12 ? '[${server.id}] ' : ''}${server.name}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDub ? cs.primaryContainer : cs.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isDub ? 'DUB' : 'SUB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDub
                      ? cs.onPrimaryContainer
                      : cs.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        children: [_buildContent(context, cs)],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRetry);
    }

    if (streams == null || streams!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          'No streams found.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: streams!.map((stream) {
        return ActionChip(
          avatar: Icon(
            Icons.download_rounded,
            size: 15,
            color: cs.onSecondaryContainer,
          ),
          label: Text(
            stream.quality,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: () => onDownload(stream),
          shape: const StadiumBorder(),
          side: BorderSide.none,
          backgroundColor: cs.secondaryContainer,
          labelStyle: TextStyle(color: cs.onSecondaryContainer),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        );
      }).toList(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.error, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
