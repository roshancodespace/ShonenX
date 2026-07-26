import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/manual_match_list.dart';
import 'package:shonenx/shared/widgets/source_selector_list.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

enum _FixStep { selectSource, searchMatch }

class FixSourceSheet extends ConsumerStatefulWidget {
  final String mediaTitle;
  final MediaType type;
  final MediaArgs? matchArgs;

  const FixSourceSheet({
    super.key,
    required this.mediaTitle,
    required this.type,
    this.matchArgs,
  });

  @override
  ConsumerState<FixSourceSheet> createState() => _FixSourceSheetState();
}

class _FixSourceSheetState extends ConsumerState<FixSourceSheet> {
  _FixStep _currentStep = _FixStep.selectSource;
  SourceInfo? _selectedSource;

  // Search Step State
  late TextEditingController _controller;
  Timer? _debounceTimer;
  List<UnifiedMedia>? _results;
  bool _isSearching = false;

  MediaArgs get _effectiveArgs =>
      widget.matchArgs ??
      MediaArgs(mediaTitle: widget.mediaTitle, type: widget.type);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.mediaTitle);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _selectedSource == null) return;

    setState(() {
      _isSearching = true;
      _results = null;
    });

    try {
      final source = widget.type == MediaType.ANIME
          ? ref.read(animeSourceProvider(_selectedSource!))
          : ref.read(mangaSourceProvider(_selectedSource!));
      final results = await source.search(cleanQuery, widget.type);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onSourceSelected(SourceInfo source) {
    setState(() {
      _selectedSource = source;
      _currentStep = _FixStep.searchMatch;
    });
    _search(_controller.text);
  }

  void _onMatchSelected(UnifiedMedia result) {
    if (_selectedSource == null) return;

    final args = _effectiveArgs;

    // Update both the source and the manual match preference
    ref
        .read(mediaPreferenceProvider(args).notifier)
        .updateSource(_selectedSource!);
    ref
        .read(mediaPreferenceProvider(args).notifier)
        .setManualMatch(result.id, result.title.availableTitle);

    ref.invalidate(matchedMediaProvider(args));
    ref.invalidate(episodesListProvider(args));

    context.pop(true);
  }

  Widget _buildSelectSourceStep() {
    final provider = widget.type == MediaType.ANIME
        ? availableAnimeSourcesProvider
        : availableMangaSourcesProvider;

    final sourcesAsync = ref.watch(provider);

    return sourcesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('Error loading sources: $e')),
      ),
      data: (sources) {
        if (sources.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Bro watched peak fiction, deleted all extensions, and expects me to magically find the episodes. Go install an extension first! 💀',
                  ),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.redAccent,
                ),
              );
              context.pop();
            }
          });
          return const SizedBox.shrink();
        }

        return SourceSelectorList(
          availableSources: sources,
          mediaType: widget.type,
          onSourceSelected: (ctx, source) => _onSourceSelected(source),
        );
      },
    );
  }

  Widget _buildSearchMatchStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: widget.type == MediaType.ANIME
                      ? 'Search Anime'
                      : 'Search Manga / Novel',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _search(_controller.text),
                        ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _search,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_results != null && _results!.isEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('No matches found.'),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-select Source'),
                  onPressed: () =>
                      setState(() => _currentStep = _FixStep.selectSource),
                ),
              ],
            ),
          ),
        if (_results != null && _results!.isNotEmpty)
          Flexible(
            child: ManualMatchList(
              results: _results,
              isLoading: _isSearching,
              onMatchSelected: (result) => _onMatchSelected(result),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: _currentStep == _FixStep.selectSource
          ? 'Fix Source: Select Extension (1/2)'
          : 'Fix Source: Match Media (2/2)',
      actions: _currentStep == _FixStep.searchMatch
          ? [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_outlined),
                tooltip: 'Change Source',
                onPressed: () =>
                    setState(() => _currentStep = _FixStep.selectSource),
              ),
            ]
          : null,
      child: _currentStep == _FixStep.selectSource
          ? _buildSelectSourceStep()
          : _buildSearchMatchStep(),
    );
  }
}
