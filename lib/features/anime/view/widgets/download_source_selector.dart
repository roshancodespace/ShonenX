// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/storage_provider.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;

class DownloadSourceSelector extends StatefulWidget {
  final String animeTitle;
  final EpisodeDataModel episode;
  final ServerData? server;
  final Future<BaseSourcesModel?> Function() fetchSources;
  final ScrollController scrollController;

  const DownloadSourceSelector({
    super.key,
    required this.animeTitle,
    required this.episode,
    required this.server,
    required this.fetchSources,
    required this.scrollController,
  });

  @override
  State<DownloadSourceSelector> createState() => DownloadSourceSelectorState();
}

class DownloadSourceSelectorState extends State<DownloadSourceSelector> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _sourceBaseHeaders;
  List<Source> _sources = [];
  List<Subtitle> _subtitles = [];

  // Expansion state
  int? _expandedIndex;
  bool _extracting = false;
  List<Map<String, dynamic>> _qualities = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final data = await widget.fetchSources();
      if (mounted) {
        setState(() {
          _sources = data?.sources ?? [];
          _subtitles = data?.tracks ?? [];
          _sourceBaseHeaders = data?.headers;
          _loading = false;
          if (_sources.isEmpty) _error = "No sources found";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _expandSource(int index, Source source) async {
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = null);
      return;
    }

    setState(() {
      _expandedIndex = index;
      _extracting = true;
      _qualities = [];
    });

    try {
      List<Map<String, dynamic>> result = [];
      if (source.url != null) {
        if (source.isM3U8) {
          result = await extractor.extractQualities(
              source.url!, source.headers ?? {});
        } else {
          result = [
            {'quality': source.quality ?? 'Default', 'url': source.url!}
          ];
        }
      }

      if (mounted) setState(() => _qualities = result);
    } catch (e) {
      // Graceful fail
      if (mounted)
        setState(() => _qualities = [
              {'quality': 'Error', 'url': ''}
            ]);
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _triggerDownload(String url, String quality,
      Map<String, String>? headers, bool isM3U8) async {
    final dir = await StorageProvider().getDefaultDirectory();
    if (dir == null) return;

    // Sanitize filenames
    final cleanAnime =
        widget.animeTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    final cleanEp = (widget.episode.title ?? "Episode ${widget.episode.number}")
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    // Extension logic: TS for M3U8, MP4 for others
    final ext = isM3U8 ? '.ts' : '.mp4';
    final path =
        "${dir.path}/$cleanAnime/${widget.episode.number} - $cleanEp/video$ext";

    final defaultHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
    };

    final item = DownloadItem(
      animeTitle: widget.animeTitle,
      episodeTitle: widget.episode.title ?? "Episode ${widget.episode.number}",
      episodeNumber: widget.episode.number ?? 0,
      thumbnail: widget.episode.thumbnail ?? '',
      state: DownloadStatus.queued,
      progress: 0,
      downloadUrl: url,
      quality: quality,
      filePath: path,
      contentType: isM3U8 ? 'application/vnd.apple.mpegurl' : 'video/mp4',
      subtitles: _subtitles.map((s) => jsonEncode(s.toJson())).toList(),
      headers: headers ?? defaultHeaders,
    );

    if (mounted) {
      ProviderScope.containerOf(context, listen: false)
          .read(downloadsProvider.notifier)
          .addDownload(item);

      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Download started')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("Error: $_error"));

    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _sources.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final source = _sources[index];
        final isExpanded = _expandedIndex == index;

        return Column(
          children: [
            ListTile(
              title: Text(source.quality ?? 'Unknown Quality'),
              subtitle: Text(source.isDub ? 'Dub' : 'Sub'),
              trailing:
                  Icon(isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1),
              onTap: () => _expandSource(index, source),
            ),
            if (isExpanded)
              if (_extracting)
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator())
              else
                ..._qualities.map((q) => ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.only(left: 32, right: 16),
                      title: Text(q['quality']),
                      trailing: const Icon(Iconsax.document_download,
                          color: Colors.blue),
                      onTap: () => _triggerDownload(
                          q['url'],
                          q['quality'],
                          {
                            ...(_sourceBaseHeaders ?? {})
                                .cast<String, String>(),
                            ...?source.headers
                          },
                          source.isM3U8),
                    )),
          ],
        );
      },
    );
  }
}
