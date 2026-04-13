import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/shared/ui/anime/anime_search_notifier.dart';

class AnimeSearchDialog extends ConsumerStatefulWidget {
  final AnimeProvider animeProvider;
  final UniversalMedia media;
  final bool autoMatch;
  final int? startAt;

  const AnimeSearchDialog({
    super.key,
    required this.animeProvider,
    required this.media,
    required this.autoMatch,
    this.startAt,
  });

  @override
  ConsumerState<AnimeSearchDialog> createState() => _AnimeSearchDialogState();
}

class _AnimeSearchDialogState extends ConsumerState<AnimeSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _searchController.text = widget.media.title.userPreferred;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(animeSearchProvider.notifier)
          .tryAutoResolve(widget.media, widget.autoMatch, _handleSelection);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSelection(BaseAnimeModel anime) {
    if (!mounted) return;
    Navigator.of(context).pop(anime);

    ref.read(animeSearchProvider.notifier).saveSelection(widget.media, anime);

    if (widget.autoMatch) {
      navigateToWatch(
        context: context,
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
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildSearchInput(),
            const SizedBox(height: 12),
            Expanded(child: _buildResults(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
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
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchController,
      onChanged: ref.read(animeSearchProvider.notifier).onSearchChanged,
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
    );
  }

  Widget _buildResults(ThemeData theme) {
    final searchState = ref.watch(animeSearchProvider);

    if (searchState.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (searchState.results.isEmpty) return _buildEmptyState(theme);

    return ListView.separated(
      itemCount: searchState.results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final anime = searchState.results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          onTap: () => _handleSelection(anime),
          leading: _buildPoster(anime),
          title: Text(
            anime.name ?? 'No Title',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: anime.releaseDate != null ? Text(anime.releaseDate!) : null,
          trailing: Icon(
            Iconsax.arrow_circle_right,
            color: theme.colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildPoster(BaseAnimeModel anime) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: anime.poster ?? '',
        width: 50,
        height: 70,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Container(
          width: 50,
          height: 70,
          color: Colors.grey[800],
          child: const Icon(Iconsax.image, size: 20),
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
