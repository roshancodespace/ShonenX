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
import 'package:shonenx/source_engine/source_engine_provider.dart';

class ManualMatchSheet extends ConsumerStatefulWidget {
  final String mediaTitle;
  final MediaType type;
  final MediaArgs? matchArgs;

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

  MediaArgs get _effectiveArgs =>
      widget.matchArgs ??
      MediaArgs(mediaTitle: widget.mediaTitle, type: widget.type);

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
        .setManualMatch(result.id, result.title.availableTitle);

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
          Flexible(
            child: ManualMatchList(
              results: _results,
              isLoading: _isLoading,
              onMatchSelected: (result) => _onSelect(result),
            ),
          ),
        ],
      ),
    );
  }
}
