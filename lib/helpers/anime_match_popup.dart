import 'dart:async';
import 'dart:developer';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/api/models/anime/anime_model.dep.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';

Future<void> providerAnimeMatchSearch({
  Function? beforeSearchCallback,
  Function? afterSearchCallback,
  required BuildContext context,
  required WidgetRef ref,
  required Media animeMedia,
  required AnimeWatchProgressBox animeWatchProgressBox,
}) async {
  if (beforeSearchCallback != null) beforeSearchCallback();

  try {
    final animeProvider = getAnimeProvider(ref);
    final title = animeMedia.title?.english ?? animeMedia.title?.romaji ?? animeMedia.title?.native;

    if (title == null || animeProvider == null) {
      throw Exception('Invalid title or anime provider');
    }

    // Initial search with the provided title
    final searchTitle = Uri.encodeComponent(title.trim());
    final initialResponse = await animeProvider.getSearch(searchTitle, animeMedia.format, 1);

    if (!context.mounted) return;

    if (initialResponse.results.isEmpty) {
      _showErrorSnackBar(context, 'Anime Not Found', 'We couldn\'t locate the anime with the selected provider.');
      return;
    }

    // Calculate similarity for initial results
    final matchedResults = initialResponse.results
        .where((result) => result.name != null && result.id != null)
        .map((result) {
          final similarity = calculateSimilarity(result.name!.toLowerCase(), title.toLowerCase());
          return (result, similarity);
        })
        .where((pair) => pair.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    if (!context.mounted) return;

    // Direct navigation for high-confidence matches
    if (matchedResults.isNotEmpty && matchedResults.first.$2 >= 0.8) {
      final bestMatch = matchedResults.first.$1;
      log("Best match found: ${bestMatch.id}");
      final encodedAnimeName = Uri.encodeComponent(bestMatch.name ?? '');
      context.push('/watch/${bestMatch.id}?animeName=$encodedAnimeName', extra: animeMedia);
      return;
    }

    // Show modern dialog with search capability
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _AnimeSearchDialog(
        initialResults: matchedResults.isEmpty ? initialResponse.results : matchedResults.map((r) => r.$1).toList(),
        animeProvider: animeProvider,
        animeMedia: animeMedia,
        animeWatchProgressBox: animeWatchProgressBox,
        initialQuery: title,
      ),
    );
  } catch (e) {
    log("Error in anime match search: $e");
    if (context.mounted) {
      _showErrorSnackBar(context, 'Error', 'Failed to load anime details. Please try again.');
    }
  } finally {
    if (afterSearchCallback != null) afterSearchCallback();
  }
}

// Helper to show error snackbar
void _showErrorSnackBar(BuildContext context, String title, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.failure,
      ),
    ),
  );
}

// Modern Anime Search Dialog
class _AnimeSearchDialog extends StatefulWidget {
  final List<BaseAnimeModel> initialResults;
  final AnimeProvider animeProvider;
  final Media animeMedia;
  final AnimeWatchProgressBox animeWatchProgressBox;
  final String initialQuery;

  const _AnimeSearchDialog({
    required this.initialResults,
    required this.animeProvider,
    required this.animeMedia,
    required this.animeWatchProgressBox,
    required this.initialQuery,
  });

  @override
  State<_AnimeSearchDialog> createState() => _AnimeSearchDialogState();
}

class _AnimeSearchDialogState extends State<_AnimeSearchDialog> {
  late TextEditingController _searchController;
  List<BaseAnimeModel> _results = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _results = widget.initialResults;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAnime(String query) async {
    if (query.isEmpty) {
      setState(() => _results = widget.initialResults);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final response = await widget.animeProvider.getSearch(encodedQuery, widget.animeMedia.format, 1);
      setState(() => _results = response.results.where((r) => r.id != null).toList());
    } catch (e) {
      log("Search error: $e");
      if (mounted) {
        _showErrorSnackBar(context, 'Search Error', 'Failed to fetch search results.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchAnime(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Anime',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.close_circle, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search anime...',
                      prefixIcon: const Icon(Iconsax.search_normal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Results List
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(child: Text('No results found', style: TextStyle(fontSize: 16)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            return _AnimeTile(
                              anime: result,
                              onTap: () {
                                Navigator.of(context).pop();
                                final continueWatchingEntry = widget.animeWatchProgressBox.getMostRecentEpisodeProgressByAnimeId(widget.animeMedia.id!);
                                final encodedAnimeName = Uri.encodeComponent(result.name ?? '');
                                if (continueWatchingEntry != null) {
                                  context.push(
                                    '/watch/${result.id}?animeName=$encodedAnimeName&episode=${continueWatchingEntry.episodeNumber}&startAt=${continueWatchingEntry.progressInSeconds}',
                                    extra: widget.animeMedia,
                                  );
                                } else {
                                  context.push(
                                    '/watch/${result.id}?animeName=$encodedAnimeName',
                                    extra: widget.animeMedia,
                                  );
                                }
                              },
                            );
                          },
                        ),
            ),
            const Divider(height: 1),
            // Cancel Button
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Anime Tile Widget
class _AnimeTile extends StatelessWidget {
  final BaseAnimeModel anime;
  final VoidCallback onTap;

  const _AnimeTile({required this.anime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Thumbnail
            if (anime.poster != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: anime.poster!,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 50,
                    height: 70,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 50,
                    height: 70,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Iconsax.image, size: 20),
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 70,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Iconsax.image, size: 20),
              ),
            const SizedBox(width: 12),
            // Title and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.name ?? 'Unknown',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (anime.releaseDate != null || anime.type != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [anime.releaseDate, anime.type].where((e) => e != null).join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3, size: 20),
          ],
        ),
      ),
    );
  }
}