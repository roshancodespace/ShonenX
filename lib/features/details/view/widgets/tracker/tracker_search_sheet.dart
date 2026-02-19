import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/tracker/tracker_models.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/details/view/widgets/tracker/tracker_config_sheet.dart';
import 'package:shonenx/features/details/view_model/external_tracker_notifier.dart';
import 'package:shonenx/shared/providers/tracker_service_providers.dart';

/// Bottom sheet for searching anime on a tracker platform (fallback when
/// the remote ID is not available in the media metadata).
class TrackerSearchSheet extends ConsumerStatefulWidget {
  final UniversalMedia media;
  final TrackerType tracker;

  const TrackerSearchSheet({
    super.key,
    required this.media,
    required this.tracker,
  });

  static Future<void> show(
    BuildContext context, {
    required UniversalMedia media,
    required TrackerType tracker,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrackerSearchSheet(media: media, tracker: tracker),
    );
  }

  @override
  ConsumerState<TrackerSearchSheet> createState() => _TrackerSearchSheetState();
}

class _TrackerSearchSheetState extends ConsumerState<TrackerSearchSheet> {
  late TextEditingController _searchController;
  List<TrackerSearchResult> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.media.title.userPreferred,
    );
    // Auto-search on open
    Future.microtask(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final service = ref.read(externalTrackerServiceProvider);
      final results = await service.searchMedia(widget.tracker, query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Search failed. Please try again.';
          _isSearching = false;
        });
      }
    }
  }

  void _onResultSelected(TrackerSearchResult result) async {
    // Bind the selected result
    final notifier = ref.read(
      externalTrackerProvider(widget.media.id).notifier,
    );
    await notifier.bindTracker(widget.media, widget.tracker, result.remoteId);

    if (!mounted) return;
    Navigator.pop(context);

    // Open config sheet with the selected remote ID
    TrackerConfigSheet.show(
      context,
      media: widget.media,
      tracker: widget.tracker,
      remoteId: result.remoteId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Icon(
                  Iconsax.search_normal,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Search on ${widget.tracker.displayName}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search anime...',
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.refresh),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),

            // Results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          Text(_error!, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: _performSearch,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        'No results found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return _buildResultTile(theme, result);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(ThemeData theme, TrackerSearchResult result) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onResultSelected(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: result.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: result.imageUrl!,
                        width: 48,
                        height: 68,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 48,
                          height: 68,
                          color: theme.colorScheme.surfaceContainer,
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 68,
                        color: theme.colorScheme.surfaceContainer,
                        child: Icon(
                          Iconsax.image,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (result.year != null) result.year.toString(),
                        result.format,
                        if (result.episodes != null) '${result.episodes} eps',
                        result.status,
                      ].whereType<String>().join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (result.score != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Iconsax.star1,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (result.score! / 10).toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Select indicator
              Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
