import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/shared/providers/mal_service_provider.dart';

class TrackerSearchSheet extends ConsumerStatefulWidget {
  final TrackerType type;
  final String initialQuery;
  final Function(UniversalMedia) onSelected;

  const TrackerSearchSheet({
    super.key,
    required this.type,
    required this.initialQuery,
    required this.onSelected,
  });

  static void show(
    BuildContext context, {
    required TrackerType type,
    required String initialQuery,
    required Function(UniversalMedia) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TrackerSearchSheet(
        type: type,
        initialQuery: initialQuery,
        onSelected: onSelected,
      ),
    );
  }

  @override
  ConsumerState<TrackerSearchSheet> createState() => _TrackerSearchSheetState();
}

class _TrackerSearchSheetState extends ConsumerState<TrackerSearchSheet> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  List<UniversalMedia> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);

    // Defer search to allow bottom sheet animation to complete smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final AnimeRepository repository = widget.type == TrackerType.anilist
          ? ref.read(anilistServiceProvider)
          : ref.read(malServiceProvider);

      final results = await repository.searchAnime(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Search failed for ${widget.type.name}', e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Link to ${widget.type.name.toUpperCase()}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              autofocus: widget.initialQuery.isEmpty,
              decoration: InputDecoration(
                hintText: 'Search anime...',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Iconsax.arrow_right_1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(theme, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: TextStyle(
            color: colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_results.isEmpty && _controller.text.isNotEmpty) {
      return Center(
        child: Text(
          'No results found.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final media = _results[index];
        final title =
            media.title.english ??
            media.title.romaji ??
            media.title.native ??
            'Unknown';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              widget.onSelected(media);
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: media.coverImage.medium ?? '',
                      width: 52,
                      height: 72,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 52,
                        height: 72,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Iconsax.image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          media.status?.toUpperCase() ?? 'UNKNOWN',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
