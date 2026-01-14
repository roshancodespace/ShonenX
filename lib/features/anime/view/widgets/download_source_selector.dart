import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/features/settings/view_model/download_settings_notifier.dart';
import 'package:shonenx/storage_provider.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;
import 'package:path/path.dart' as p;

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
  State<DownloadSourceSelector> createState() => _DownloadSourceSelectorState();
}

class _DownloadSourceSelectorState extends State<DownloadSourceSelector> {
  bool _loading = true;
  String? _error;
  List<Source> _sources = [];
  List<Subtitle> _subtitles = [];
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
            source.url!,
            source.headers ?? {},
          );
        } else {
          result = [
            {'quality': source.quality ?? 'Default', 'url': source.url!},
          ];
        }
      }
      if (mounted) setState(() => _qualities = result);
    } catch (_) {
      if (mounted) {
        setState(
          () => _qualities = [
            {'quality': 'Error', 'url': ''},
          ],
        );
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _triggerDownload(
    String url,
    String quality,
    Map<String, String>? headers,
    bool isM3U8,
  ) async {
    final providerContext = ProviderScope.containerOf(context);
    final settings = providerContext.read(downloadSettingsProvider);
    final notifier = providerContext.read(downloadsProvider.notifier);
    final baseDir = settings.useCustomPath
        ? (settings.customDownloadPath != null
              ? Directory(settings.customDownloadPath!)
              : null)
        : await StorageProvider().getDefaultDirectory();
    if (baseDir == null) return;

    final cleanAnime = widget.animeTitle
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .trim();
    final episodeNumber = widget.episode.number ?? 0;
    final cleanEpTitle = (widget.episode.title ?? 'Episode $episodeNumber')
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .trim();

    final animeDir = Directory(p.join(baseDir.path, cleanAnime));
    final episodeDir = Directory(
      p.join(animeDir.path, '$episodeNumber - $cleanEpTitle'),
    );
    if (!await episodeDir.exists()) await episodeDir.create(recursive: true);

    final ext = isM3U8 ? '.ts' : '.mp4';
    final filePath = p.join(episodeDir.path, 'video$ext');

    final finalHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      ...?headers,
    };

    final item = DownloadItem(
      animeTitle: widget.animeTitle,
      episodeTitle: widget.episode.title ?? 'Episode $episodeNumber',
      episodeNumber: episodeNumber,
      thumbnail: widget.episode.thumbnail ?? '',
      state: DownloadStatus.queued,
      progress: 0,
      downloadUrl: url,
      quality: quality,
      filePath: filePath,
      subtitles: _subtitles.map((s) => jsonEncode(s.toJson())).toList(),
      headers: finalHeaders,
    );

    if (!mounted) return;
    notifier.addDownload(item);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Download started')));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("Error: $_error"));

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _sources.length,
      itemBuilder: (context, index) {
        final source = _sources[index];
        final isExpanded = _expandedIndex == index;

        final hasMultipleQualities =
            _qualities.length > 1 || (source.isM3U8 && _qualities.isEmpty);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.quality ?? 'Unknown Quality',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            source.isDub ? 'Dub' : 'Sub',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        hasMultipleQualities
                            ? (isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded)
                            : Icons.download_rounded,
                      ),
                      onPressed: hasMultipleQualities
                          ? () => _expandSource(index, source)
                          : () {
                              final q = _qualities.isNotEmpty
                                  ? _qualities.first
                                  : {
                                      'url': source.url!,
                                      'quality': source.quality ?? 'Default',
                                    };
                              _triggerDownload(q['url'], q['quality'], {
                                ...?source.headers,
                              }, source.isM3U8);
                            },
                    ),
                  ],
                ),
                if (isExpanded && _qualities.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _qualities.map((q) {
                        return ActionChip(
                          label: Text(q['quality']),
                          onPressed: () => _triggerDownload(
                            q['url'],
                            q['quality'],
                            {...?source.headers},
                            source.isM3U8,
                          ),
                          backgroundColor: colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (isExpanded && _extracting)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
