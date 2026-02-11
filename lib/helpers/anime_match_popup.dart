import 'dart:async';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/isar/models/isar_anime_watch_progress.dart';
import 'package:shonenx/features/anime/services/anime_match_service.dart';
import 'package:shonenx/features/settings/view_model/content_settings_notifier.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
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
  bool showSnackbar = false,
}) async {
  beforeSearchCallback?.call();

  try {
    // Smart Source Persistence Check
    final restoredAnime = await ref
        .read(animeMatchServiceProvider)
        .restoreSource(animeMedia.id.toString(), showSnackbar: showSnackbar);

    if (restoredAnime != null) {
      if (withAnimeMatch) {
        AppLogger.d('Navigating to watch screen...');
        if (context.mounted) {
          navigateToWatch(
            context: context,
            ref: ref,
            mediaId: animeMedia.id.toString(),
            animeId: restoredAnime.id!,
            animeName: restoredAnime.name ?? 'Unknown',
            animeFormat: animeMedia.format ?? '',
            animeCover: restoredAnime.poster ?? '',
            episodes: const [],
            currentEpisode: startAt ?? 1,
          );
        }
        return restoredAnime;
      }
    }

    final animeProvider = ref.read(selectedAnimeProvider);
    if (animeProvider == null) throw Exception('Anime provider is missing.');
    if (!context.mounted) return null;
    return await showDialog<BaseAnimeModel>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AnimeSearchDialog(
        animeProvider: animeProvider,
        media: animeMedia,
        autoMatch: withAnimeMatch,
        startAt: startAt,
      ),
    );
  } catch (e, s) {
    AppLogger.e('Search failed', e, s);
    if (context.mounted) {
      showAppSnackBar(
        'Error',
        'Failed to load details.',
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
  final UniversalMedia media;
  final bool autoMatch;
  final int? startAt;

  const _AnimeSearchDialog({
    required this.animeProvider,
    required this.media,
    required this.autoMatch,
    this.startAt,
  });

  @override
  ConsumerState<_AnimeSearchDialog> createState() => _AnimeSearchDialogState();
}

class _AnimeSearchDialogState extends ConsumerState<_AnimeSearchDialog> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<BaseAnimeModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tryAutoResolve();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Tries English -> Romaji -> Native titles sequentially
  Future<void> _tryAutoResolve() async {
    if (widget.autoMatch) {
      final match = await ref
          .read(animeMatchServiceProvider)
          .findBestMatch(widget.media.title);

      if (!mounted) return;

      if (match != null) {
        _handleSelection(match);
        return;
      }
    }

    // Fallback: search for the first available title to show results
    final title = widget.media.title.userPreferred;
    _searchController.text = title;
    await _performSearch(title, autoMatch: false);
  }

  Future<bool> _performSearch(String query, {bool autoMatch = false}) async {
    setState(() => _isLoading = true);

    try {
      final results = await _fetchFromSource(query);
      if (!mounted) return false;

      setState(() => _results = results);
      return true;
    } catch (e) {
      AppLogger.e('Search error', e);
      setState(() => _results = []);
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<BaseAnimeModel>> _fetchFromSource(String query) async {
    return ref.read(animeMatchServiceProvider).search(query);
  }

  void _handleSelection(BaseAnimeModel anime) {
    if (!mounted) return;
    Navigator.of(context).pop(anime);

    // Save Smart Source Preference
    try {
      final settings = ref.read(contentSettingsProvider);
      AppLogger.d(
        'Saving Source Pref: Enabled = ${settings.smartSourceEnabled}',
      );

      if (settings.smartSourceEnabled) {
        final useMangayomi = ref
            .read(experimentalProvider)
            .useMangayomiExtensions;
        String? sourceId;
        String? sourceType;

        if (useMangayomi) {
          AppLogger.d('Saving Source Pref: Mangayomi mode active');
          final source = ref.read(sourceProvider).activeAnimeSource;
          if (source != null) {
            sourceId = source.id.toString();
            sourceType = 'mangayomi';
          } else {
            AppLogger.w('Saving Source Pref: Active source is null');
          }
        } else {
          AppLogger.d('Saving Source Pref: Legacy mode active');
          final provider = ref.read(selectedAnimeProvider);
          if (provider != null) {
            sourceId = ref.read(selectedProviderKeyProvider);
            sourceType = 'legacy';
          } else {
            AppLogger.w('Saving Source Pref: Selected provider is null');
          }
        }

        AppLogger.d('Saving Source Pref: ID=$sourceId, Type=$sourceType');

        if (sourceId != null && sourceType != null) {
          final repo = ref.read(watchProgressRepositoryProvider);
          repo.saveSourceSelection(
            widget.media.id.toString(),
            (widget.media.coverImage.medium ?? widget.media.coverImage.large)!,
            IsarSourceSelection(
              sourceId: sourceId,
              sourceType: sourceType,
              matchedAnimeId: anime.id,
              matchedAnimeTitle: anime.name,
            ),
          );
          AppLogger.d(
            'Saving Source Pref: Call to saveSourceSelection made for anime ${widget.media.id}',
          );
        }
      }
    } catch (e, st) {
      AppLogger.e('Failed to save smart source preference', e, st);
    }

    if (widget.autoMatch) {
      navigateToWatch(
        context: context,
        ref: ref,
        mediaId: widget.media.id.toString(),
        animeId: anime.id!,
        animeName: anime.name ?? 'Unknown',
        animeFormat: widget.media.format ?? '',
        animeCover:
            anime.poster ??
            widget.media.coverImage.large ??
            widget.media.coverImage.medium ??
            '',
        episodes: const [],
        currentEpisode: widget.startAt ?? 1,
      );
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _performSearch(query, autoMatch: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Anime Source',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Input
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search anime title...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),

            // List / Loading / Error
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final anime = _results[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          onTap: () => _handleSelection(anime),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: anime.poster ?? '',
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 50,
                                height: 70,
                                color: Colors.grey[800],
                                child: const Icon(Iconsax.image, size: 20),
                              ),
                            ),
                          ),
                          title: Text(
                            anime.name ?? 'No Title',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: anime.releaseDate != null
                              ? Text(anime.releaseDate!)
                              : null,
                          trailing: Icon(
                            Iconsax.arrow_circle_right,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.search_status, size: 48, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text('No matches found', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
