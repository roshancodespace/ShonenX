import 'dart:async';
import 'dart:ui';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/main.dart';

Future<BaseAnimeModel?> providerAnimeMatchSearch({
  Function? beforeSearchCallback,
  Function? afterSearchCallback,
  required BuildContext context,
  required WidgetRef ref,
  required UniversalMedia animeMedia,
  bool withAnimeMatch = true,
  int? startAt,
}) async {
  beforeSearchCallback?.call();

  final title = animeMedia.title;
  AppLogger.d(
    'Starting anime match search for anime: ${title.english ?? title.romaji ?? title.native}',
  );

  try {
    final animeProvider = ref.read(selectedAnimeProvider);
    if (animeProvider == null) {
      throw Exception('Anime provider is missing.');
    }

    final result = await showDialog<BaseAnimeModel>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AnimeSearchDialog(
        animeProvider: animeProvider,
        animeMedia: animeMedia,
        withAnimeMatch: withAnimeMatch,
        startAt: startAt,
      ),
    );
    return result;
  } catch (e, stackTrace) {
    AppLogger.e('Anime match search failed', e, stackTrace);
    if (context.mounted) {
      showAppSnackBar(
        'Error',
        'Failed to load anime details.',
        type: ContentType.failure,
      );
    }
    return null;
  } finally {
    afterSearchCallback?.call();
  }
}

class _AnimeSearchDialog extends ConsumerStatefulWidget {
  final AnimeProvider animeProvider;
  final UniversalMedia animeMedia;
  final bool withAnimeMatch;
  final int? startAt;

  const _AnimeSearchDialog({
    required this.animeProvider,
    required this.animeMedia,
    required this.withAnimeMatch,
    this.startAt,
  });

  @override
  ConsumerState<_AnimeSearchDialog> createState() => _AnimeSearchDialogState();
}

class _AnimeSearchDialogState extends ConsumerState<_AnimeSearchDialog> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  List<BaseAnimeModel> _results = [];
  bool _isLoading = true;
  Timer? _debounceTimer;
  // String? _currentSearchTerm;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initSearch() async {
    final title = widget.animeMedia.title;
    final titles = [
      title.english,
      title.romaji,
      title.native,
    ].where((t) => t != null && t.trim().isNotEmpty).cast<String>().toList();

    if (titles.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _searchController.text = titles.first;

    for (final title in titles) {
      if (!mounted) return;

      if (_searchController.text != title) {
        _searchController.text = title;
      }

      final success = await _performSearch(
        title,
        autoMatch: widget.withAnimeMatch,
      );
      if (success) return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (_results.isEmpty) {
        _searchFocusNode.requestFocus();
      }
    }
  }

  Future<bool> _performSearch(String query, {bool autoMatch = false}) async {
    if (!mounted) return false;
    setState(() => _isLoading = true);
    List<BaseAnimeModel> fetchedCandidates = [];

    try {
      final useMangayomi = ref
          .read(experimentalProvider)
          .useMangayomiExtensions;

      // Mangayomi Extensions
      if (useMangayomi) {
        final activeSource = ref.read(sourceProvider).activeAnimeSource;
        if (activeSource != null && (activeSource.isForShonenx ?? false)) {
          AppLogger.d('Using ShonenX Mangayomi for search with query: $query');
          final res = await ref.read(sourceProvider.notifier).search(query);
          fetchedCandidates = res.list
              .where((e) => e.name != null && e.link != null)
              .map(
                (e) => BaseAnimeModel(
                  id: e.link ?? '',
                  name: e.name ?? '',
                  poster: e.imageUrl ?? '',
                ),
              )
              .toList();
        } else {
          // Standard Mangayomi Extensions
          AppLogger.d('Using Standard Mangayomi for search with query: $query');
          final res = await ref.read(sourceProvider.notifier).search(query);
          fetchedCandidates = res.list
              .where((e) => e.name != null && e.link != null)
              .map(
                (e) => BaseAnimeModel(
                  id: e.link ?? '',
                  name: e.name ?? '',
                  poster: e.imageUrl ?? '',
                ),
              )
              .toList();
        }
      }
      // Legacy Source
      else {
        AppLogger.d('Using Legacy source for search with query: $query');
        final res = await widget.animeProvider.getSearch(query.trim(), null, 1);
        fetchedCandidates = res.results
            .where((e) => e.name != null && e.id != null)
            .toList();
      }

      if (!mounted) return false;

      if (fetchedCandidates.isEmpty) {
        if (!autoMatch) {
          setState(() {
            _results = [];
            _isLoading = false;
          });
        }
        return false; // Indicate no results found or no auto-match occurred
      }

      if (autoMatch) {
        final matches = getBestMatches<BaseAnimeModel>(
          results: fetchedCandidates,
          title: query,
          nameSelector: (r) => r.name!,
          idSelector: (r) => r.id!,
        );

        if (matches.isNotEmpty && matches.first.similarity >= 0.8) {
          final bestMatch = matches.first.result;
          AppLogger.d('✅ High-confidence match found: ${bestMatch.name}');

          if (mounted) {
            Navigator.of(context).pop(); // Close the dialog
            navigateToWatch(
              context: context,
              ref: ref,
              mediaId: widget.animeMedia.id.toString(),
              animeId: bestMatch.id!,
              animeName: bestMatch.name!,
              animeFormat: widget.animeMedia.format ?? '',
              animeCover:
                  bestMatch.poster ??
                  widget.animeMedia.coverImage.large ??
                  widget.animeMedia.coverImage.medium ??
                  '',
              episodes: const [],
              currentEpisode: widget.startAt ?? 1,
            );
          }
          return true;
        }
      }

      setState(() {
        _results = fetchedCandidates;
        _isLoading = false;
      });
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Search failed for $query', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = [];
        });
        showAppSnackBar(
          'Error',
          'Failed to search for anime. Please try again.',
          type: ContentType.failure,
        );
      }
      return false;
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) return;
    _debounceTimer = Timer(
      const Duration(milliseconds: 600),
      () => _performSearch(query, autoMatch: false),
    );
  }

  void _selectAnime(BaseAnimeModel anime) {
    Navigator.of(context).pop(anime);
    if (!widget.withAnimeMatch) return;
    navigateToWatch(
      context: context,
      ref: ref,
      mediaId: widget.animeMedia.id.toString(),
      animeId: anime.id!,
      animeFormat: widget.animeMedia.format ?? '',
      animeCover:
          widget.animeMedia.coverImage.large ??
          widget.animeMedia.coverImage.medium ??
          '',
      animeName: anime.name ?? 'Unknown',
      episodes: const [],
      currentEpisode: widget.startAt ?? 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.search_favorite,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Anime Source',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Choose the correct match below',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search anime title...',
                  prefixIcon: const Icon(Iconsax.search_normal_1),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow.withOpacity(
                      0.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.05),
                    ),
                  ),
                  child: _buildResultsContent(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsContent(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching for best match...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_status,
              size: 64,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Matches Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different title',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _AnimeTile(
        anime: _results[index],
        onTap: () => _selectAnime(_results[index]),
      ),
    );
  }
}

class _AnimeTile extends StatelessWidget {
  final BaseAnimeModel anime;
  final VoidCallback onTap;

  const _AnimeTile({required this.anime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = [
      anime.releaseDate,
      anime.type,
    ].where((s) => s != null && s.isNotEmpty).join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.05),
            ),
            color: theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              Hero(
                tag: anime.id ?? anime.name ?? 'unknown',
                child: Container(
                  width: 60,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: anime.poster ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Iconsax.image,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.name ?? 'No Title',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          metadata,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Iconsax.arrow_circle_right,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
