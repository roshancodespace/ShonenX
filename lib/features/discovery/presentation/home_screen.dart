import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
            ...sections
                .where((s) => !s.disabled)
                .map(
                  (section) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildSectionWidget(context, section, feedState),
                    ),
                  ),
                ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWidget(
    BuildContext context,
    HomeSection section,
    AsyncValue<HomeFeedState> feedState,
  ) {
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

      case HomeSectionType.trending:
        return _buildFeedGroups(context, feedState, mediaType);
    }
  }

  Widget _buildFeedGroups(
    BuildContext context,
    AsyncValue<HomeFeedState> feedState,
    MediaType mediaType,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final prefs = ref.watch(discoveryPrefsProvider);
        if (prefs.mode == MetadataMode.source) {
          return _buildSourceSectionRows(context, ref, mediaType, prefs);
        }

        return feedState.when(
          data: (feed) {
            if (feed.groups.isEmpty) return const SizedBox.shrink();

            final filteredGroups = feed.groups.where((g) {
              if (g.items.isEmpty) return false;
              return g.items.first.type == mediaType;
            }).toList();

            if (filteredGroups.isEmpty) return const SizedBox.shrink();

            return Column(
              children: filteredGroups
                  .map(
                    (group) => _buildFeedRow(context, group.title, group.items),
                  )
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildSourceSectionRows(
    BuildContext context,
    WidgetRef ref,
    MediaType mediaType,
    DiscoveryPrefs prefs,
  ) {
    final allSourcesAsync = mediaType == MediaType.ANIME
        ? ref.watch(availableAnimeSourcesProvider)
        : ref.watch(availableMangaSourcesProvider);

    return allSourcesAsync.when(
      data: (allSources) {
        final activeSources = allSources
            .where((s) => prefs.activeSources.contains(s.id))
            .toList();

        if (activeSources.isEmpty) return const SizedBox.shrink();

        return Column(
          children: activeSources.map((info) {
            final title =
                '${info.name} (${mediaType == MediaType.ANIME ? "Anime" : "Manga"})';
            return _buildSingleSourceRow(context, ref, info, mediaType, title);
          }).toList(),
        );
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
    final sourceData = ref.watch(singleSourceFeedProvider((info, mediaType)));

    return HorizontalSection<UnifiedMedia>(
      title: title,
      height: style.layout.height,
      onMoreTap: () => context.push('/category/$title?type=${mediaType.id}'),
      data: sourceData,
      itemBuilder: (context, item) {
        return MediaCard(
          tag: '$title-${item.id}',
          format: item.format,
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

  Widget _buildFeedRow(
    BuildContext context,
    String title,
    List<UnifiedMedia> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, child) {
        final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
        final mediaType = items.isNotEmpty ? items.first.type : MediaType.ANIME;
        return HorizontalSection(
          title: title,
          height: style.layout.height,
          onMoreTap: () =>
              context.push('/category/$title?type=${mediaType.id}'),
          data: AsyncValue.data(items),
          itemBuilder: (context, item) {
            return MediaCard(
              tag: '$title-${item.id}',
              format: item.format,
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
      },
    );
  }
}
