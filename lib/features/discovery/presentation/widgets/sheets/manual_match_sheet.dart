import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class ManualMatchSheet extends ConsumerStatefulWidget {
  final String mediaTitle;
  final MediaType type;
  final MatchArgs? matchArgs;

  const ManualMatchSheet({
    super.key,
    required this.mediaTitle,
    required this.type,
    this.matchArgs,
  });

  @override
  ConsumerState<ManualMatchSheet> createState() => _ManualMatchSheetState();
}

class _ManualMatchSheetState extends ConsumerState<ManualMatchSheet> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  List<UnifiedMedia>? _results;
  bool _isLoading = false;

  MatchArgs get _effectiveArgs =>
      widget.matchArgs ??
      MatchArgs(mediaTitle: widget.mediaTitle, type: widget.type);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.mediaTitle);
    _search(widget.mediaTitle);
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
    if (cleanQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final pref = await ref.read(
        mediaPreferenceProvider(_effectiveArgs).future,
      );
      final source = widget.type == MediaType.ANIME
          ? ref.read(animeSourceProvider(pref.sourceInfo))
          : ref.read(mangaSourceProvider(pref.sourceInfo));
      final results = await source.search(cleanQuery, widget.type);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSelect(UnifiedMedia result) {
    final args = _effectiveArgs;

    ref
        .read(mediaPreferenceProvider(args).notifier)
        .setManualOverrides(result.id, result.title.availableTitle);

    ref.invalidate(matchedMediaProvider(args));
    ref.invalidate(episodesListProvider(args));

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Manual Match',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.type == MediaType.ANIME
                  ? 'Search Anime'
                  : 'Search Manga / Novel',
              border: const OutlineInputBorder(),
              suffixIcon: _isLoading
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
          const SizedBox(height: 16),
          if (_results != null && _results!.isEmpty && !_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No matches found')),
            ),

          if (_results != null && _results!.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final result = _results![index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: result.cover != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: result.cover!,
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const SizedBox(
                            width: 40,
                            height: 60,
                            child: Icon(Icons.movie_creation_outlined),
                          ),
                    title: Text(
                      result.title.availableTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => _onSelect(result),
                      child: const Text('Match'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
