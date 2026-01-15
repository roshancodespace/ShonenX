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

  final Map<int, List<Map<String, dynamic>>> _extractedCache = {};
  final Set<int> _extractingIndices = {};
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.fetchSources();
      if (!mounted) return;

      if (data == null) {
        setState(() {
          _error = "No sources available";
          _loading = false;
        });
        return;
      }

      setState(() {
        _sources = data.sources;
        _subtitles = data.tracks;
        _loading = false;
        if (_sources.isEmpty) _error = "No video sources found";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _expandSource(int index, Source source) async {
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = null);
      return;
    }

    setState(() => _expandedIndex = index);

    if (_extractedCache.containsKey(index)) return;

    setState(() => _extractingIndices.add(index));

    try {
      final url = source.url;
      if (url == null || url.isEmpty) throw Exception("URL missing");

      List<Map<String, dynamic>> result = [];
      if (source.isM3U8) {
        result = await extractor
            .extractQualities(url, source.headers ?? {})
            .timeout(const Duration(seconds: 15));
      } else {
        result = [
          {'quality': source.quality ?? 'Default', 'url': url},
        ];
      }

      if (mounted) {
        setState(() => _extractedCache[index] = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _extractedCache[index] = [
            {'quality': 'Error loading qualities', 'url': ''},
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _extractingIndices.remove(index));
      }
    }
  }

  Future<void> _triggerDownload(
    String? url,
    String quality,
    Map<String, String>? headers,
    bool isM3U8,
  ) async {
    if (url == null || url.isEmpty) return;

    try {
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
      final epNum = widget.episode.number ?? 0;
      final cleanEpTitle = (widget.episode.title ?? 'Episode $epNum')
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
          .trim();

      final epDir = Directory(
        p.join(baseDir.path, cleanAnime, '$epNum - $cleanEpTitle'),
      );
      if (!await epDir.exists()) await epDir.create(recursive: true);

      final ext = isM3U8 ? '.ts' : '.mp4';
      final filePath = p.join(epDir.path, 'video$ext');

      final item = DownloadItem(
        animeTitle: widget.animeTitle,
        episodeTitle: widget.episode.title ?? 'Episode $epNum',
        episodeNumber: epNum,
        thumbnail: widget.episode.thumbnail ?? '',
        state: DownloadStatus.queued,
        progress: 0,
        downloadUrl: url,
        quality: quality,
        filePath: filePath,
        subtitles: _subtitles.map((s) => jsonEncode(s.toJson())).toList(),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...',
          ...?headers,
        },
      );

      notifier.addDownload(item);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download started')));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _init, child: Text("Retry")),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: _sources.length,
      itemBuilder: (context, index) {
        final source = _sources[index];
        final isExpanded = _expandedIndex == index;
        final cachedQualities = _extractedCache[index] ?? [];
        final isExtracting = _extractingIndices.contains(index);

        return Card(
          key: ValueKey('source_$index'),
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            maintainState: true,
            initiallyExpanded: isExpanded,
            onExpansionChanged: (val) => _expandSource(index, source),
            title: Text(
              source.quality ?? 'Source ${index + 1}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(source.isDub ? 'Dubbed' : 'Subtitled'),
            trailing: isExtracting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            children: [
              if (cachedQualities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cachedQualities.map((q) {
                        final isErr = q['quality'].toString().contains('Error');
                        return ActionChip(
                          label: Text(q['quality']),
                          onPressed: isErr
                              ? null
                              : () => _triggerDownload(
                                  q['url'],
                                  q['quality'],
                                  source.headers,
                                  source.isM3U8,
                                ),
                          backgroundColor: isErr
                              ? colorScheme.errorContainer
                              : colorScheme.secondaryContainer,
                        );
                      }).toList(),
                    ),
                  ),
                )
              else if (!isExtracting)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Loading quality options..."),
                ),
            ],
          ),
        );
      },
    );
  }
}
