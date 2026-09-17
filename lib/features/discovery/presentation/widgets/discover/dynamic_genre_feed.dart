import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/providers/discovery_feed_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shonenx/features/recommendations/domain/models/recommended_anime.dart';
import 'package:shonenx/features/recommendations/presentation/widgets/quick_status_sheet.dart';
import 'package:shonenx/features/recommendations/providers/recommendations_provider.dart';

class DynamicGenreFeed extends ConsumerWidget {
  final MediaType type;
  final ValueChanged<String>? onGenreSelect;
  final EdgeInsetsGeometry? padding;

  const DynamicGenreFeed({
    super.key,
    required this.type,
    this.onGenreSelect,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresState = ref.watch(discoveryFeedGenresProvider);
    final profileState = ref.watch(userTasteProfileProvider);
    final hasSignals = profileState.value?.hasAnySignals ?? false;
    final effectivePadding =
        padding ?? const EdgeInsets.only(top: 60, bottom: 200);

    return genresState.when(
      data: (genres) {
        if (genres.isEmpty && !hasSignals) {
          return const Center(child: Text('No categories available'));
        }

        final totalCount = genres.length + (hasSignals ? 1 : 0);

        return ListView.builder(
          padding: effectivePadding,
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (hasSignals && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: _RecommendedFeedRow(type: type),
              );
            }
            final genreIndex = hasSignals ? index - 1 : index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: GenreFeedRow(
                type: type,
                genre: genres[genreIndex],
                onGenreSelect: onGenreSelect,
              ),
            );
          },
        );
      },
      loading: () {
        final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
        final isWide = ref.watch(
          uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
        );
        final height = style.getLayout(isWideMode: isWide).height;

        return Skeletonizer(
          enabled: true,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 200),
            itemCount: 3,
            itemBuilder: (context, index) {
              return HorizontalSection<UnifiedMedia>(
                title: 'Loading Genre Category',
                height: height,
                data: const AsyncValue.loading(),
                itemBuilder: (_, __) => const SizedBox.shrink(),
                skeletonItemBuilder: (context, i) {
                  return MediaCard(
                    tag: 'skeleton-genre-$index-$i',
                    title: 'Placeholder Media Title Name',
                    imageUrl: '',
                    style: style,
                    format: 'TV',
                    score: 8.5,
                    year: '2026',
                    onTap: () {},
                  );
                },
              );
            },
          ),
        );
      },
      error: (e, _) => Center(child: Text('Failed to load feed: $e')),
    );
  }
}

class GenreFeedRow extends ConsumerWidget {
  final MediaType type;
  final String genre;
  final ValueChanged<String>? onGenreSelect;

  const GenreFeedRow({
    super.key,
    required this.type,
    required this.genre,
    this.onGenreSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (type: type, genre: genre);
    final feedState = ref.watch(genreFeedProvider(arg));
    final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
    );

    return feedState.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return HorizontalSection(
          title: genre,
          height: style.getLayout(isWideMode: isWide).height,
          onMoreTap: () {
            if (onGenreSelect != null) {
              onGenreSelect!(genre);
            } else {
              context.pushFilteredDiscover(genres: [genre], type: type);
            }
          },
          data: AsyncValue.data(items),
          itemBuilder: (context, item) {
            return MediaCard(
              tag: 'feed-$genre-${item.id}',
              format: item.format,
              score: item.score,
              status: item.status,
              genres: item.genres,
              year: item.season,
              title: item.title.availableTitle,
              imageUrl: item.cover ?? '',
              style: style,
              onTap: () => context.pushDetails(
                mediaType: item.type,
                media: item,
                tag: 'feed-$genre-${item.id}',
              ),
              onLongPress: () => QuickStatusSheet.show(context, item),
            );
          },
        );
      },
      loading: () => HorizontalSection<UnifiedMedia>(
        title: genre,
        height: style.getLayout(isWideMode: isWide).height,
        data: const AsyncValue.loading(),
        itemBuilder: (_, __) => const SizedBox.shrink(),
        skeletonItemBuilder: (context, index) {
          return MediaCard(
            tag: 'skeleton-genre-row-$genre-$index',
            title: 'Placeholder Media Title Name',
            imageUrl: '',
            style: style,
            format: 'TV',
            score: 8.5,
            year: '2026',
            onTap: () {},
          );
        },
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _RecommendedFeedRow extends ConsumerWidget {
  final MediaType type;

  const _RecommendedFeedRow({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recState = ref.watch(recommendedAnimeFeedProvider(type));
    final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
    );

    return recState.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return HorizontalSection<RecommendedAnime>(
          title: 'Recommended For You',
          height: style.getLayout(isWideMode: isWide).height,
          data: AsyncValue.data(items),
          itemBuilder: (context, rec) {
            final item = rec.media;
            return MediaCard(
              tag: 'discover-rec-${item.id}',
              format: item.format,
              score: item.score,
              status: item.status,
              genres: item.genres,
              year: item.season,
              subtitle: rec.reason,
              title: item.title.availableTitle,
              imageUrl: item.cover ?? '',
              style: style,
              onTap: () => context.pushDetails(
                mediaType: item.type,
                media: item,
                tag: 'discover-rec-${item.id}',
              ),
              onLongPress: () => QuickStatusSheet.show(context, item),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

