import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MultiSourceSearchFeed extends ConsumerWidget {
  final MediaType type;
  final String query;
  final List<String> genres;
  final List<String> tags;
  final ValueChanged<String>? onSourceSelect;

  const MultiSourceSearchFeed({
    super.key,
    required this.type,
    required this.query,
    this.genres = const [],
    this.tags = const [],
    this.onSourceSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(discoveryPrefsProvider);
    final sourcesAsync = type == MediaType.ANIME
        ? ref.watch(availableAnimeSourcesProvider)
        : ref.watch(availableMangaSourcesProvider);

    return sourcesAsync.when(
      data: (allSources) {
        final active = allSources
            .where((s) => prefs.activeSources.contains(s.id))
            .toList();

        if (active.isEmpty) {
          return Center(
            child: Text(
              'No active sources found. Enable extensions in settings.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 70, bottom: 120),
          itemCount: active.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SourceSearchRow(
                type: type,
                query: query,
                genres: genres,
                tags: tags,
                info: active[index],
                onSourceSelect: onSourceSelect,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading sources: $e')),
    );
  }
}

class SourceSearchRow extends ConsumerWidget {
  final MediaType type;
  final String query;
  final List<String> genres;
  final List<String> tags;
  final SourceInfo info;
  final ValueChanged<String>? onSourceSelect;

  const SourceSearchRow({
    super.key,
    required this.type,
    required this.query,
    required this.genres,
    required this.tags,
    required this.info,
    this.onSourceSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = SearchArgs(
      query: query,
      type: type,
      genres: genres,
      tags: tags,
      source: info.id,
    );

    final state = ref.watch(searchProvider(args));

    final uiState = ref.watch(uiPrefsProvider);
    final style = uiState.cardStyle;
    final isWide = uiState.isMediaCardWide(style.name);
    final scale = ref.watch(themePrefsProvider).uiScaleFactor;
    final height = style.getScaledLayout(scale, isWideMode: isWide).height;

    final AsyncValue<List<UnifiedMedia>> listState = state.when(
      data: (res) {
        if (res == null) return const AsyncValue.data([]);
        return AsyncValue.data(res.items);
      },
      error: (e, s) => AsyncValue.error(e, s),
      loading: () => const AsyncValue.loading(),
    );

    return HorizontalSection<UnifiedMedia>(
      title: info.name,
      height: height,
      data: listState,
      onMoreTap: () {
        if (onSourceSelect != null) {
          onSourceSelect!(info.id);
        }
      },
      itemBuilder: (context, item) {
        return MediaCard(
          tag: 'search-src-${info.id}-${item.id}',
          title: item.title.availableTitle,
          imageUrl: item.cover ?? '',
          style: style,
          score: item.score,
          format: item.format,
          year: item.season,
          onTap: () {
            context.pushDetails(
              mediaType: type,
              media: item,
              tag: 'search-src-${info.id}-${item.id}',
            );
          },
        );
      },
      skeletonItemBuilder: (context, i) {
        return Skeletonizer(
          enabled: true,
          child: MediaCard(
            tag: 'search-skeleton-${info.id}-$i',
            title: 'Placeholder Media Title Name',
            imageUrl: '',
            style: style,
            format: 'TV',
            score: 8.5,
            year: '2026',
            onTap: () {},
          ),
        );
      },
    );
  }
}
