import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/manual_match_list.dart';

import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';

class ManualTrackerMatchSheet extends ConsumerStatefulWidget {
  final String mediaTitle;
  final MediaType type;
  final TrackerType targetTracker;

  const ManualTrackerMatchSheet({
    super.key,
    required this.mediaTitle,
    required this.type,
    required this.targetTracker,
  });

  @override
  ConsumerState<ManualTrackerMatchSheet> createState() =>
      _ManualTrackerMatchSheetState();
}

class _ManualTrackerMatchSheetState
    extends ConsumerState<ManualTrackerMatchSheet> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  List<UnifiedMedia>? _results;
  bool _isLoading = false;

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
      final trackers = ref.read(availableTrackersProvider);
      final trackerService = trackers.firstWhere(
        (t) => t.type == widget.targetTracker,
      );
      if (trackerService is RemoteTracker) {
        final results = await trackerService.searchMedia(
          cleanQuery,
          type: widget.type,
        );
        if (mounted) {
          setState(
            () => _results = results
                .map(
                  (r) => UnifiedMedia(
                    id: r.id,
                    type: widget.type,
                    title: r.title,
                    cover: r.cover,
                  ),
                )
                .toList(),
          );
        }
      } else {
        if (mounted) setState(() => _results = []);
      }
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSelect(UnifiedMedia result) {
    ref
        .read(
          mediaPreferenceProvider(
            MediaArgs(mediaTitle: widget.mediaTitle, type: widget.type),
          ).notifier,
        )
        .setTrackerMediaId(result.id);

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
          Flexible(
            child: ManualMatchList(
              results: _results,
              isLoading: _isLoading,
              onMatchSelected: _onSelect,
            ),
          ),
        ],
      ),
    );
  }
}
