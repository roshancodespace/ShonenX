import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final epNumStr = episode.number.toString().contains('.0')
        ? episode.number.toInt().toString()
        : episode.number.toString();
    return AppBottomSheet.show(
      context: context,
      title: 'Download Episode $epNumStr',
      titleIcon: Icons.download_rounded,
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

  final Map<String, String> _streamSizes = {};

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
      if (mounted) {
        setState(() => _servers = servers);
        if (servers.length == 1) {
          _loadStreams(servers.first);
        }
      }
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
                size: q.size,
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
        _fetchStreamSizes(splitStreamsList);
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

  Future<void> _fetchStreamSizes(List<VideoStream> streams) async {
    final httpClient = ref.read(httpClientProvider);
    for (final stream in streams) {
      if (_streamSizes.containsKey(stream.url) || stream.size != null) continue;
      try {
        final uri = Uri.parse(stream.url);
        final cleanPath = uri.path.toLowerCase();
        if (!cleanPath.endsWith('.m3u8') && !cleanPath.endsWith('.m3u')) {
          final res = await httpClient.head(
            stream.url,
            headers: stream.headers,
          );
          final len = res.headers?['content-length'];
          if (len != null) {
            final bytes = int.tryParse(len);
            if (bytes != null && bytes > 0) {
              if (mounted) {
                setState(() {
                  _streamSizes[stream.url] = _formatBytes(bytes);
                });
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOneDMInstalledAsync = ref.watch(isOneDMInstalledProvider);
    final isOneDMInstalled = isOneDMInstalledAsync.value ?? false;

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

    if (_servers!.length == 1) {
      final server = _servers!.first;
      final key = _serverKey(server);
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 2,
                right: 2,
                top: 4,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${server.id.length <= 12 ? '[${server.id}] ' : ''}${server.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _ServerTypeBadge(type: server.type),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildStreamsList(
              context,
              cs,
              server: server,
              streams: _streamsCache[key],
              isLoading: _loadingStreams.contains(key),
              error: _streamErrors[key],
              isOneDMInstalled: isOneDMInstalled,
              onRetry: () => _loadStreams(server),
            ),
          ],
        ),
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
            isOneDMInstalled: isOneDMInstalled,
            streamSizes: _streamSizes,
            onExpand: () => _loadStreams(server),
            onRetry: () => _loadStreams(server),
            onDownload: (stream) => _startDownload(stream, server),
            on1DMDownload: (stream) => _start1DMDownload(stream),
            onExternalPlayer: (stream) => _launchExternalPlayer(stream),
            onCopyUrl: (stream) => _copyStreamUrl(stream),
          );
        }),
      ),
    );
  }

  Widget _buildStreamsList(
    BuildContext context,
    ColorScheme cs, {
    required VideoServer server,
    required List<VideoStream>? streams,
    required bool isLoading,
    required String? error,
    required bool isOneDMInstalled,
    required VoidCallback onRetry,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (error != null) {
      return _ErrorState(message: error, onRetry: onRetry);
    }

    if (streams == null || streams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'No streams found for this server.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    return Column(
      children: streams.map((stream) {
        final size = _streamSizes[stream.url] ?? stream.size;
        final labelText = (size != null && size.isNotEmpty)
            ? '${stream.quality} ($size)'
            : stream.quality;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              RawChip(
                avatar: Icon(
                  Icons.video_library_rounded,
                  size: 14,
                  color: cs.onSecondaryContainer,
                ),
                label: Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: cs.secondaryContainer,
                labelStyle: TextStyle(color: cs.onSecondaryContainer),
                shape: const StadiumBorder(),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copy Stream Link',
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 17,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => _copyStreamUrl(stream),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Play in External Player',
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 17,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => _launchExternalPlayer(stream),
                  ),
                  if (isOneDMInstalled && Platform.isAndroid)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Download via 1DM',
                      icon: Icon(
                        Icons.cloud_download_outlined,
                        size: 17,
                        color: cs.primary,
                      ),
                      onPressed: () => _start1DMDownload(stream),
                    ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Download',
                    icon: const Icon(Icons.download_rounded, size: 17),
                    onPressed: () => _startDownload(stream, server),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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

  Future<void> _start1DMDownload(VideoStream stream) async {
    final epNum = widget.episode.number.toString().contains('.0')
        ? widget.episode.number.toInt().toString()
        : widget.episode.number.toString();
    final fileName =
        '${widget.media.title.availableTitle} - Episode $epNum.mp4';

    final success = await OneDMService.instance.download(
      url: stream.url,
      fileName: fileName,
      headers: stream.headers,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sent stream to 1DM')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to launch 1DM')));
      }
    }
  }

  void _copyStreamUrl(VideoStream stream) {
    Clipboard.setData(ClipboardData(text: stream.url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stream URL copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchExternalPlayer(VideoStream stream) async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: stream.url,
          type: 'video/*',
          arguments: {
            if (stream.headers != null)
              'android.media.intent.extra.HTTP_HEADERS': stream.headers,
            'title':
                '${widget.media.title.availableTitle} - Ep ${widget.episode.number}',
          },
        );
        await intent.launch();
        if (mounted) Navigator.of(context).pop();
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to launch external player: $e')),
          );
        }
        return;
      }
    }

    final title =
        '${widget.media.title.availableTitle} - Ep ${widget.episode.number}';
    bool launched = false;

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // 1. Try mpv
      try {
        final List<String> args = [];
        if (stream.headers != null && stream.headers!.isNotEmpty) {
          final headerStr = stream.headers!.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(',');
          args.add('--http-header-fields=$headerStr');
        }
        args.add('--force-media-title=$title');
        args.add(stream.url);

        await Process.start('mpv', args);
        launched = true;
      } catch (_) {}

      // 2. Try vlc
      if (!launched) {
        try {
          final List<String> args = [];
          if (stream.headers != null &&
              stream.headers!.containsKey('Referer')) {
            args.add('--http-referrer=${stream.headers!['Referer']}');
          }
          if (stream.headers != null &&
              stream.headers!.containsKey('User-Agent')) {
            args.add('--http-user-agent=${stream.headers!['User-Agent']}');
          }
          args.add('--meta-title=$title');
          args.add(stream.url);

          await Process.start('vlc', args);
          launched = true;
        } catch (_) {}
      }
    }

    // 3. Fallback to system default application / url_launcher
    if (!launched) {
      try {
        final uri = Uri.parse(stream.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
        }
      } catch (_) {}
    }

    if (mounted) {
      if (launched) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening stream in external player...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not launch external player. Make sure MPV, VLC, or a video player is installed.',
            ),
          ),
        );
      }
    }
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.streams,
    required this.isLoading,
    required this.error,
    required this.isOneDMInstalled,
    required this.streamSizes,
    required this.onExpand,
    required this.onRetry,
    required this.onDownload,
    required this.on1DMDownload,
    required this.onExternalPlayer,
    required this.onCopyUrl,
  });

  final VideoServer server;
  final List<VideoStream>? streams;
  final bool isLoading;
  final String? error;
  final bool isOneDMInstalled;
  final Map<String, String> streamSizes;
  final VoidCallback onExpand;
  final VoidCallback onRetry;
  final void Function(VideoStream) onDownload;
  final void Function(VideoStream) on1DMDownload;
  final void Function(VideoStream) onExternalPlayer;
  final void Function(VideoStream) onCopyUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            _ServerTypeBadge(type: server.type),
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

    return Column(
      children: streams!.map((stream) {
        final size = streamSizes[stream.url] ?? stream.size;
        final labelText = (size != null && size.isNotEmpty)
            ? '${stream.quality} ($size)'
            : stream.quality;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              RawChip(
                avatar: Icon(
                  Icons.video_library_rounded,
                  size: 14,
                  color: cs.onSecondaryContainer,
                ),
                label: Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: cs.secondaryContainer,
                labelStyle: TextStyle(color: cs.onSecondaryContainer),
                shape: const StadiumBorder(),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copy Stream Link',
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 17,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => onCopyUrl(stream),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Play in External Player',
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 17,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => onExternalPlayer(stream),
                  ),
                  if (isOneDMInstalled && Platform.isAndroid)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Download via 1DM',
                      icon: Icon(
                        Icons.cloud_download_outlined,
                        size: 17,
                        color: cs.primary,
                      ),
                      onPressed: () => on1DMDownload(stream),
                    ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Download',
                    icon: const Icon(Icons.download_rounded, size: 17),
                    onPressed: () => onDownload(stream),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ServerTypeBadge extends StatelessWidget {
  final ServerType type;
  const _ServerTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDub = type == ServerType.dub;
    final isSub = type == ServerType.sub;

    final bgColor = isDub
        ? cs.primaryContainer.withValues(alpha: 0.5)
        : isSub
        ? cs.secondaryContainer.withValues(alpha: 0.5)
        : cs.surfaceContainerHighest;

    final textColor = isDub
        ? cs.onPrimaryContainer
        : isSub
        ? cs.onSecondaryContainer
        : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
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
