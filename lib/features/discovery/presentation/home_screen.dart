import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final sections = ref.watch(userHomeLayoutProvider);
    final feedState = ref.watch(homeFeedProvider);
    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(homeFeedProvider.notifier).refresh();
          ref.invalidate(singleSourceFeedProvider);
          for (final section in sections) {
            if (section.type == HomeSectionType.libraryStatus &&
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

                                return IconButton.filledTonal(
                                  visualDensity: VisualDensity.standard,
                                  tooltip: 'Discovery Mode',
                                  onPressed: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    useRootNavigator: true,
                                    builder: (_) => const DiscoveryModeSheet(),
                                  ),
                                  iconSize: 20,
                                  icon: Icon(
                                    isTracker
                                        ? Icons.cloud_outlined
                                        : Icons.extension_outlined,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                    foregroundColor:
                                        theme.colorScheme.onSecondary,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.standard,
                              tooltip: 'Settings',
                              iconSize: 20,
                              onPressed: () => context.push('/settings'),
                              icon: const Icon(Icons.settings_outlined),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
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
                      feedState,
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
          final prefs = ref.watch(discoveryPrefsProvider);
          final activeSources = allSources
              .where((s) => prefs.activeSources.contains(s.id))
              .toList();
          final sourcesToUse = activeSources.isEmpty
              ? allSources
              : activeSources;
          if (sourcesToUse.isEmpty) return const [];
          final sourceInfo = sourcesToUse.first;
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

  Widget _buildSectionWidget(
    BuildContext context,
    HomeSection section,
    AsyncValue<HomeFeedState> feedState, {
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
          onMoreTap: () => context.push(
            '/category/${Uri.encodeComponent(section.title)}?type=${mediaType.id}',
          ),
          data: data,
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
              onTap: () => context.push(
                '/details/${item.type.id}?tag=${section.id}-${item.id}',
                extra: item,
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
        final activeSources = prefs.activeSources.isEmpty
            ? allSources
            : allSources
                  .where((s) => prefs.activeSources.contains(s.id))
                  .toList();

        final effectiveSources = activeSources.isEmpty
            ? allSources
            : activeSources;

        if (effectiveSources.isEmpty) return const SizedBox.shrink();

        if (totalDiscoverySections <= 1) {
          return Column(
            children: effectiveSources.map((info) {
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

        if (discoveryIndex >= effectiveSources.length) {
          return const SizedBox.shrink();
        }

        final info = effectiveSources[discoveryIndex];
        final title =
            '${info.name} (${mediaType == MediaType.ANIME ? "Anime" : "Manga"})';
        return _buildSingleSourceRow(context, ref, info, mediaType, title);
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
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
      onMoreTap: () => context.push(
        '/category/${Uri.encodeComponent(title)}?type=${mediaType.id}',
      ),
      data: sourceData,
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
          onTap: () => context.push(
            '/details/${item.type.id}?tag=$title-${item.id}',
            extra: item,
          ),
        );
      },
    );
  }
}
