import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';

class LinkTrackerSheet extends ConsumerStatefulWidget {
  final String primaryMediaId;
  final MediaType mediaType;
  final String initialSearchQuery;
  final RemoteTracker tracker;

  const LinkTrackerSheet({
    super.key,
    required this.primaryMediaId,
    required this.initialSearchQuery,
    required this.mediaType,
    required this.tracker,
  });

  @override
  ConsumerState<LinkTrackerSheet> createState() => _LinkTrackerSheetState();
}

class _LinkTrackerSheetState extends ConsumerState<LinkTrackerSheet> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  List<TrackerSearchResult>? _results;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialSearchQuery);
    _search(widget.initialSearchQuery);
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
      final results = await widget.tracker.searchMedia(
        cleanQuery,
        type: widget.mediaType,
      );
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSelect(TrackerSearchResult result) {
    ref
        .read(trackerLinkProvider(widget.primaryMediaId).notifier)
        .saveLink(
          widget.tracker.type,
          TrackerMapping()
            ..trackingId = result.id
            ..trackerId = widget.tracker.type.id
            ..trackingTitle = result.title,
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Link to ${widget.tracker.type.displayName}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Search Anime',
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

          // Results Area
          if (_results != null && _results!.isEmpty && !_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No results found')),
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
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => _onSelect(result),
                      child: const Text('Link'),
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
