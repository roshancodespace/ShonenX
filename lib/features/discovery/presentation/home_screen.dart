import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue_watching_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/local_library_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

import 'widgets/cloud_library_row.dart';

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
          for (final section in sections) {
            if (section.type == HomeSectionType.cloudLibraryStatus) {
              ref
                  .read(cloudLibraryProvider(section.libraryStatus!).notifier)
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: theme.colorScheme.primaryContainer,
                            padding: const EdgeInsets.all(2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl:
                                    profiles[primaryTrackerType]?.avatarUrl ??
                                    '',
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person_outline_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Welcome back,\n',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: theme.colorScheme.primaryContainer,
                                      height: 1,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              TextSpan(
                                text:
                                    profiles[primaryTrackerType]?.username ??
                                    'Guest',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Consumer(
                          builder: (context, modeRef, _) {
                            final mode = modeRef.watch(
                              discoveryPrefsProvider.select((p) => p.mode),
                            );
                            return IconButton.outlined(
                              visualDensity: VisualDensity.standard,
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                useRootNavigator: true,
                                builder: (_) => const DiscoveryModeSheet(),
                              ),
                              tooltip: 'Discovery Mode',
                              icon: Icon(
                                mode == MetadataMode.tracker
                                    ? Icons.cloud_outlined
                                    : Icons.extension_outlined,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          visualDensity: VisualDensity.standard,
                          onPressed: () => context.push('/settings'),
                          tooltip: 'Settings',
                          icon: const Icon(Icons.settings_outlined),
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

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
    switch (section.type) {
      case HomeSectionType.continueWatching:
        return ContinueWatchingRow(title: section.title);

      case HomeSectionType.cloudLibraryStatus:
        if (section.libraryStatus == null) return const SizedBox.shrink();
        return CloudLibraryRowWidget(
          title: section.title,
          status: section.libraryStatus!,
        );

      case HomeSectionType.localLibraryStatus:
        if (section.libraryStatus == null) return const SizedBox.shrink();
        return LocalLibraryRow(
          title: section.title,
          status: section.libraryStatus!,
        );

      case HomeSectionType.trending:
      case HomeSectionType.popular:
        return _buildFeedGroups(context, feedState);
    }
  }

  Widget _buildFeedGroups(
    BuildContext context,
    AsyncValue<HomeFeedState> feedState,
  ) {
    return feedState.when(
      data: (feed) {
        if (feed.groups.isEmpty) return const SizedBox.shrink();

        return Column(
          children: feed.groups
              .map((group) => _buildFeedRow(context, group.title, group.items))
              .toList(),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
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
        return HorizontalSection(
          title: title,
          height: style.layout.height,
          data: AsyncValue.data(items),
          itemBuilder: (context, item) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: MediaCard(
                tag: '$title-${item.id}',
                title: item.title.availableTitle,
                imageUrl: item.cover ?? '',
                style: style,
                onTap: () => context.push(
                  '/details/${item.type.name}?tag=$title-${item.id}',
                  extra: item,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
