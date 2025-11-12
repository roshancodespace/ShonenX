import 'dart:async';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/main.dart';

/// Searches for an anime match and navigates to the watch screen.
///
/// It first attempts a high-confidence automatic match. If unsuccessful,
/// it displays a search dialog for manual selection.
Future<void> providerAnimeMatchSearch({
  Function? beforeSearchCallback,
  Function? afterSearchCallback,
  required BuildContext context,
  required WidgetRef ref,
  required Media animeMedia,
}) async {
  beforeSearchCallback?.call();
  AppLogger.d('Starting anime match search for animeId: ${animeMedia.id}');

  try {
    final animeProvider = ref.read(selectedAnimeProvider);
    if (animeProvider == null) {
      throw Exception('Anime provider is missing.');
    }

    // Collect titles in priority order
    final titles = [
      animeMedia.title?.english,
      animeMedia.title?.romaji,
      animeMedia.title?.native,
    ].where((t) => t != null && t.trim().isNotEmpty).cast<String>().toList();

    if (titles.isEmpty) {
      throw Exception('No valid titles available for search.');
    }

    List<BaseAnimeModel>? fallbackResults;
    String? usedTitle;

    // Try each title until one gives confident match or usable results
    for (final title in titles) {
      AppLogger.d('🔎 Trying search with title: $title');

      final initialResponse = await animeProvider.getSearch(
        Uri.encodeComponent(title.trim()),
        animeMedia.format,
        1,
      );

      if (!context.mounted) return;

      if (initialResponse.results.isEmpty) {
        AppLogger.d('No results for "$title". Trying next title...');
        continue;
      }

      // Step 2: calculate similarity
      final matches = getBestMatches<BaseAnimeModel>(
        results: initialResponse.results,
        title: title,
        nameSelector: (r) => r.name,
        idSelector: (r) => r.id,
      );

      if (!context.mounted) return;

      if (matches.isNotEmpty && matches.first.similarity >= 0.8) {
        final bestMatch = matches.first.result;
        usedTitle = title;
        AppLogger.d(
            '✅ High-confidence match found: ${bestMatch.name} (via "$title")');

        navigateToWatch(
            context: context,
            ref: ref,
            mediaId: animeMedia.id.toString(),
            animeId: bestMatch.id!,
            animeName: bestMatch.name!,
            episodes: const [],
            currentEpisode: 1);
        return;
      }

      // No confident match → store results for manual selection
      fallbackResults = initialResponse.results;
      usedTitle = title;
      break;
    }

    // If no results from any title
    if (fallbackResults == null || fallbackResults.isEmpty) {
      showAppSnackBar(
        'Anime Not Found',
        'We couldn\'t locate this anime with any available title.',
        type: ContentType.failure,
      );
      return;
    }

    // Show manual selection dialog
    await showDialog(
      context: context,
      builder: (_) => _AnimeSearchDialog(
        initialResults: fallbackResults ?? [],
        animeProvider: animeProvider,
        animeMedia: animeMedia,
        initialQuery: usedTitle ?? titles.first,
      ),
    );
  } catch (e, stackTrace) {
    AppLogger.e('Anime match search failed', e, stackTrace);
    if (context.mounted) {
      showAppSnackBar(
        'Error',
        'Failed to load anime details.',
        type: ContentType.failure,
      );
    }
  } finally {
    afterSearchCallback?.call();
  }
}

/// A minimal dialog for searching and selecting an anime.
class _AnimeSearchDialog extends ConsumerStatefulWidget {
  final List<BaseAnimeModel> initialResults;
  final AnimeProvider animeProvider;
  final Media animeMedia;
  final String initialQuery;

  const _AnimeSearchDialog({
    required this.initialResults,
    required this.animeProvider,
    required this.animeMedia,
    required this.initialQuery,
  });

  @override
  ConsumerState<_AnimeSearchDialog> createState() => _AnimeSearchDialogState();
}

class _AnimeSearchDialogState extends ConsumerState<_AnimeSearchDialog> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  List<BaseAnimeModel> _results = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _results = widget.initialResults;
    _searchController = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) return;
    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () => _searchAnime(query),
    );
  }

  Future<void> _searchAnime(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await widget.animeProvider.getSearch(
          Uri.encodeComponent(query.trim()), widget.animeMedia.format, 1);
      if (mounted) {
        setState(() =>
            _results = response.results.where((r) => r.id != null).toList());
      }
    } catch (e, stackTrace) {
      AppLogger.e('Anime search in dialog failed', e, stackTrace);
      if (mounted) {
        showAppSnackBar('Search Error', 'Could not fetch results.',
            type: ContentType.failure);
        setState(() => _results = []);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAnime(BaseAnimeModel anime) {
    Navigator.of(context).pop();
    navigateToWatch(
      context: context,
      ref: ref,
      mediaId: widget.animeMedia.id.toString(),
      animeId: anime.id!,
      animeName: anime.name ?? 'Unknown',
      episodes: const [],
      currentEpisode: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find Your Anime', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Select the correct match or try a new search.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResultsContent(theme)),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_status, size: 48, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('No Anime Found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Try different keywords.', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      itemBuilder: (context, index) => _AnimeTile(
        anime: _results[index],
        onTap: () => _selectAnime(_results[index]),
      ),
    );
  }
}

/// A minimal, stateless widget to display an anime search result.
class _AnimeTile extends StatelessWidget {
  final BaseAnimeModel anime;
  final VoidCallback onTap;

  const _AnimeTile({required this.anime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = [anime.releaseDate, anime.type]
        .where((s) => s != null && s.isNotEmpty)
        .join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      hoverColor: theme.colorScheme.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: anime.poster ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(Iconsax.image, color: theme.disabledColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    anime.name ?? 'No Title',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      metadata,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Iconsax.arrow_right_3,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
