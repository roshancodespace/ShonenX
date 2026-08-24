import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/library_row.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: active
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final sections = ref.watch(userHomeLayoutProvider);

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(singleSourceFeedProvider);
          for (final section in sections) {
            if (section.type == HomeSectionType.libraryStatus &&
                section.libraryStatus != null &&
                section.targetTracker != TrackerType.local) {
              ref
                  .read(
                    cloudLibraryProvider((
                      status: section.libraryStatus!,
                      trackerType: section.targetTracker,
                      mediaType: section.targetMediaType ?? MediaType.ANIME,
                    )).notifier,
                  )
                  .refresh();
            }
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Consumer(
                  builder: (context, headerRef, child) {
                    final profiles = headerRef.watch(trackerProfileProvider);
                    final primaryTrackerType = headerRef.watch(
                      primaryTrackerProvider.select((s) => s.type),
                    );

                    return Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              builder: (_) => TrackerProfileSheet(
                                trackerType: primaryTrackerType,
                              ),
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      ref.watch(
                                        themePrefsProvider.select(
                                          (s) => s.uiRoundness,
                                        ),
                                      ),
                                    ),
                                    color: theme.colorScheme.primaryContainer,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      GlobalUI.uiRoundness,
                                    ),
                                    child: TrackerAvatarWidget(
                                      imageUrl: profiles[primaryTrackerType]
                                          ?.avatarUrl,
                                      size: 48,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Welcome back',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profiles[primaryTrackerType]
                                                ?.username ??
                                            'Guest',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              height: 1.1,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer(
                              builder: (context, modeRef, _) {
                                final mode = modeRef.watch(
                                  discoveryPrefsProvider.select((p) => p.mode),
                                );

                                final isTracker = mode == MetadataMode.tracker;

                                return _HeaderButton(
                                  tooltip: 'Discovery Mode',
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    useRootNavigator: true,
                                    builder: (_) => const DiscoveryModeSheet(),
                                  ),
                                  icon: isTracker
                                      ? Icons.cloud_outlined
                                      : Icons.extension_outlined,
                                  active: isTracker,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _HeaderButton(
                              tooltip: 'Settings',
                              onTap: () => context.pushSettings(),
                              icon: Icons.settings_outlined,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            ...() {
              final discoveryIndexMap = <MediaType, int>{};
              final totalDiscoveryCounts = <MediaType, int>{};
              final activeSections = sections
                  .where((s) => !s.disabled)
                  .toList();
              for (final s in activeSections) {
                if (s.type == HomeSectionType.discovery) {
                  final mt = s.targetMediaType ?? MediaType.ANIME;
                  totalDiscoveryCounts[mt] =
                      (totalDiscoveryCounts[mt] ?? 0) + 1;
                }
              }

              return activeSections.map((section) {
                int? dIndex;
                int totalCount = 0;
                if (section.type == HomeSectionType.discovery) {
                  final mt = section.targetMediaType ?? MediaType.ANIME;
                  dIndex = discoveryIndexMap[mt] ?? 0;
                  discoveryIndexMap[mt] = dIndex + 1;
                  totalCount = totalDiscoveryCounts[mt] ?? 1;
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildSectionWidget(
                      context,
                      section,
                      discoveryIndex: dIndex,
                      totalDiscoverySections: totalCount,
                    ),
                  ),
                );
              });
            }(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
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
              tag: '${section.id}-${item.id}',
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
                tag: '${section.id}-${item.id}',
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
          tag: '$title-${item.id}',
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
            tag: '$title-${item.id}',
          ),
        );
      },
    );
  }
}

final categorySectionFeedProvider =
    FutureProvider.family<List<UnifiedMedia>, (TrackerCategory, MediaType)>((
      ref,
      arg,
    ) async {
      final category = arg.$1;
      final mediaType = arg.$2;
      final mode = ref.watch(discoveryPrefsProvider.select((p) => p.mode));

      if (mode == MetadataMode.tracker) {
        final tracker = ref.watch(metadataSourceProvider);
        final adultMode = ref.watch(contentPrefsProvider).adultContentMode;
        final result = await tracker.getCategoryItems(
          category,
          type: mediaType,
          adultMode: adultMode,
          cacheDuration: const Duration(hours: 12),
        );
        return result.items;
      } else {
        final allSources = mediaType == MediaType.ANIME
            ? await ref.watch(availableAnimeSourcesProvider.future)
            : await ref.watch(availableMangaSourcesProvider.future);
        final activeSources = ref.watch(
          discoveryPrefsProvider.select((p) => p.activeSources),
        );
        final filteredSources = allSources
            .where((s) => activeSources.contains(s.id))
            .toList();
        if (filteredSources.isEmpty) return const [];
        final sourceInfo = filteredSources.first;
        final source = mediaType == MediaType.ANIME
            ? ref.read(animeSourceProvider(sourceInfo))
            : ref.read(mangaSourceProvider(sourceInfo));
        var items = await source.getTrending();
        if (items.isEmpty) {
          items = await source.search('', mediaType);
        }
        return items;
      }
    });
