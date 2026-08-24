import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/presentation/home_screen.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/library_row.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_hero_spotlight.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class TvHomeScreen extends ConsumerWidget {
  const TvHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(userHomeLayoutProvider);
    final activeSections = sections.where((s) => !s.disabled).toList();

    // Find the first discovery section to use for the hero spotlight
    final firstDiscoverySection = activeSections
        .where((s) => s.type == HomeSectionType.discovery)
        .firstOrNull;

    final spotlightData = firstDiscoverySection != null
        ? ref.watch(
            categorySectionFeedProvider((
              firstDiscoverySection.trackerCategory ?? TrackerCategory.trending,
              firstDiscoverySection.targetMediaType ?? MediaType.ANIME,
            )),
          )
        : null;

    final spotlightItems = spotlightData?.value ?? [];

    // Build discovery index map (same logic as HomeScreen)
    final discoveryIndexMap = <MediaType, int>{};
    final totalDiscoveryCounts = <MediaType, int>{};
    for (final s in activeSections) {
      if (s.type == HomeSectionType.discovery) {
        final mt = s.targetMediaType ?? MediaType.ANIME;
        totalDiscoveryCounts[mt] = (totalDiscoveryCounts[mt] ?? 0) + 1;
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Hero Spotlight Carousel
        if (spotlightItems.isNotEmpty)
          TvHeroSpotlight(
            items: spotlightItems.take(8).toList(),
            onPlayMedia: (media) {
              context.pushDetails(
                mediaType: media.type,
                media: media,
                tag: 'tv-hero-${media.id}',
              );
            },
            onDetailsMedia: (media) {
              context.pushDetails(
                mediaType: media.type,
                media: media,
                tag: 'tv-hero-${media.id}',
              );
            },
          ),

        const SizedBox(height: 12),

        // Render user-configured sections in order
        ...activeSections.map((section) {
          int? dIndex;
          int totalCount = 0;
          if (section.type == HomeSectionType.discovery) {
            final mt = section.targetMediaType ?? MediaType.ANIME;
            dIndex = discoveryIndexMap[mt] ?? 0;
            discoveryIndexMap[mt] = dIndex + 1;
            totalCount = totalDiscoveryCounts[mt] ?? 1;
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSectionWidget(
              context,
              section,
              discoveryIndex: dIndex,
              totalDiscoverySections: totalCount,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionWidget(
    BuildContext context,
    HomeSection section, {
    int? discoveryIndex,
    int totalDiscoverySections = 1,
  }) {
    final mediaType = section.targetMediaType ?? MediaType.ANIME;

    switch (section.type) {
      case HomeSectionType.continueMedia:
        return ContinueMediaRow(title: section.title, type: mediaType);

      case HomeSectionType.libraryStatus:
        if (section.libraryStatus == null) return const SizedBox.shrink();
        return Consumer(
          builder: (context, ref, _) {
            final activeTracker = section.targetTracker != null
                ? ref
                      .watch(availableTrackersProvider)
                      .firstWhere((t) => t.type == section.targetTracker!)
                : ref.watch(primaryTrackerProvider);

            return LibraryRow(
              title: section.title,
              status: section.libraryStatus!,
              targetTracker: activeTracker.type,
              targetMediaType: mediaType,
            );
          },
        );

      case HomeSectionType.discovery:
        return _buildDiscoverySectionRow(
          context,
          section,
          discoveryIndex: discoveryIndex,
          totalDiscoverySections: totalDiscoverySections,
        );
    }
  }

  Widget _buildDiscoverySectionRow(
    BuildContext context,
    HomeSection section, {
    int? discoveryIndex,
    int totalDiscoverySections = 1,
  }) {
    final mediaType = section.targetMediaType ?? MediaType.ANIME;
    final category = section.trackerCategory ?? TrackerCategory.trending;

    return Consumer(
      builder: (context, ref, _) {
        final prefs = ref.watch(discoveryPrefsProvider);
        if (prefs.mode == MetadataMode.source) {
          return _buildSourceSectionRows(
            context,
            ref,
            mediaType,
            prefs,
            discoveryIndex ?? 0,
            totalDiscoverySections,
          );
        }

        final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
        final isWide = ref.watch(
          uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
        );
        final data = ref.watch(
          categorySectionFeedProvider((category, mediaType)),
        );

        return HorizontalSection<UnifiedMedia>(
          title: section.title,
          height: style.getLayout(isWideMode: isWide).height,
          onMoreTap: () =>
              context.pushDiscover(category: section.title, type: mediaType),
          data: data,
          skeletonItemBuilder: (context, index) {
            return MediaCard(
              tag: 'skeleton-${section.id}-$index',
              title: 'Placeholder Media Title Name',
              imageUrl: '',
              style: style,
              format: 'TV',
              score: 8.5,
              year: '2026',
              onTap: () {},
            );
          },
          itemBuilder: (context, item) {
            return MediaCard(
              tag: 'tv-${section.id}-${item.id}',
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
                tag: 'tv-${section.id}-${item.id}',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSourceSectionRows(
    BuildContext context,
    WidgetRef ref,
    MediaType mediaType,
    DiscoveryPrefs prefs,
    int discoveryIndex,
    int totalDiscoverySections,
  ) {
    final allSourcesAsync = mediaType == MediaType.ANIME
        ? ref.watch(availableAnimeSourcesProvider)
        : ref.watch(availableMangaSourcesProvider);

    return allSourcesAsync.when(
      data: (allSources) {
        final activeSources = allSources
            .where((s) => prefs.activeSources.contains(s.id))
            .toList();

        if (activeSources.isEmpty) {
          return const SizedBox.shrink();
        }

        if (totalDiscoverySections <= 1) {
          return Column(
            children: activeSources.map((info) {
              final title =
                  '${info.name} (${mediaType == MediaType.ANIME ? "Anime" : "Manga"})';
              return _buildSingleSourceRow(
                context,
                ref,
                info,
                mediaType,
                title,
              );
            }).toList(),
          );
        }

        if (discoveryIndex >= activeSources.length) {
          return const SizedBox.shrink();
        }

        final info = activeSources[discoveryIndex];
        final title =
            '${info.name} (${mediaType == MediaType.ANIME ? "Anime" : "Manga"})';
        return _buildSingleSourceRow(context, ref, info, mediaType, title);
      },
      loading: () {
        final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
        final isWide = ref.watch(
          uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
        );
        final height = style.getLayout(isWideMode: isWide).height;

        return Skeletonizer(
          enabled: true,
          child: Column(
            children: List.generate(2, (sIndex) {
              return HorizontalSection<UnifiedMedia>(
                title: 'Loading Source Section',
                height: height,
                data: const AsyncValue.loading(),
                itemBuilder: (_, __) => const SizedBox.shrink(),
                skeletonItemBuilder: (context, index) {
                  return MediaCard(
                    tag: 'skeleton-src-$sIndex-$index',
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
            }),
          ),
        );
      },
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSingleSourceRow(
    BuildContext context,
    WidgetRef ref,
    SourceInfo info,
    MediaType mediaType,
    String title,
  ) {
    final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
    );
    final sourceData = ref.watch(singleSourceFeedProvider((info, mediaType)));

    return HorizontalSection<UnifiedMedia>(
      title: title,
      height: style.getLayout(isWideMode: isWide).height,
      onMoreTap: () => context.pushDiscover(category: title, type: mediaType),
      data: sourceData,
      skeletonItemBuilder: (context, index) {
        return MediaCard(
          tag: 'skeleton-src-${info.id}-$index',
          title: 'Placeholder Media Title Name',
          imageUrl: '',
          style: style,
          format: 'TV',
          score: 8.5,
          year: '2026',
          onTap: () {},
        );
      },
      itemBuilder: (context, item) {
        return MediaCard(
          tag: 'tv-$title-${item.id}',
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
            tag: 'tv-$title-${item.id}',
          ),
        );
      },
    );
  }
}
