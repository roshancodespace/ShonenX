import 'dart:async';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/app_card_group.dart';
import 'package:shonenx/shared/widgets/app_empty_state.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

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
            ..trackingTitle = result.title.getPreferedTitle,
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(contentPrefsProvider);

    return AppBottomSheet(
      title: 'Link to ${widget.tracker.type.displayName}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText:
                  'Search ${widget.mediaType == MediaType.MANGA ? 'Manga' : 'Anime'}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: AppProgressIndicator(
                          type: AppProgressType.circular,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => _search(_controller.text),
                    ),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _search,
          ),
          const SizedBox(height: 16),

          if (_results != null && _results!.isEmpty && !_isLoading)
            const AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results found',
              subtitle: 'Try a different title or alternative spelling.',
            ),

          if (_results != null && _results!.isNotEmpty)
            Flexible(
              child: SingleChildScrollView(
                child: AppCardGroup(
                  padding: EdgeInsets.zero,
                  children: _results!.map((result) {
                    return AppCardSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onTap: () => _onSelect(result),
                      child: Row(
                        children: [
                          result.cover != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SmartImage(
                                    imageUrl: result.cover!,
                                    width: 42,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const SizedBox(
                                  width: 42,
                                  height: 60,
                                  child: Icon(Icons.movie_creation_outlined),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              result.title.getPreferedTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AppButton(
                            label: 'Link',
                            variant: AppButtonVariant.tonal,
                            size: AppButtonSize.small,
                            onPressed: () => _onSelect(result),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
