import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/library_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';

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
    final activeSections = ref.watch(homeFeedSectionsProvider);

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(singleSourceFeedProvider);
          for (final section in activeSections) {
            if (section.isDiscovery) {
              ref.invalidate(homeSectionFeedProvider(section));
            } else if (section.isLibraryStatus &&
                section.homeSection?.libraryStatus != null &&
                section.homeSection?.targetTracker != TrackerType.local) {
              ref
                  .read(
                    cloudLibraryProvider((
                      status: section.homeSection!.libraryStatus!,
                      trackerType: section.homeSection!.targetTracker,
                      mediaType: section.mediaType,
                    )).notifier,
                  )
                  .refresh();
            }
          }
        },
        child: CustomScrollView(
          slivers: [
            // Top Header Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: _buildHeader(context, ref, theme),
              ),
            ),

            if (activeSections.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No active sections or sources')),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final section = activeSections[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildSectionWidget(context, ref, section),
                  );
                }, childCount: activeSections.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme) {
    final profiles = ref.watch(trackerProfileProvider);
    final primaryTrackerType = ref.watch(
      primaryTrackerProvider.select((s) => s.type),
    );
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
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
              builder: (_) =>
                  TrackerProfileSheet(trackerType: primaryTrackerType),
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(uiRoundness),
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                    child: TrackerAvatarWidget(
                      imageUrl: profiles[primaryTrackerType]?.avatarUrl,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome back',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profiles[primaryTrackerType]?.username ?? 'Guest',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
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
  }

  Widget _buildSectionWidget(
    BuildContext context,
    WidgetRef ref,
    HomeFeedSection section,
  ) {
    switch (section.type) {
      case HomeSectionType.continueMedia:
        return ContinueMediaRow(title: section.title, type: section.mediaType);

      case HomeSectionType.libraryStatus:
        final hs = section.homeSection;
        if (hs == null || hs.libraryStatus == null) {
          return const SizedBox.shrink();
        }
        final activeTracker = hs.targetTracker != null
            ? ref
                  .watch(availableTrackersProvider)
                  .firstWhere((t) => t.type == hs.targetTracker!)
            : ref.watch(primaryTrackerProvider);

        return LibraryRow(
          title: section.title,
          status: hs.libraryStatus!,
          targetTracker: activeTracker.type,
          targetMediaType: section.mediaType,
        );

      case HomeSectionType.discovery:
        final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
        final isWide = ref.watch(
          uiPrefsProvider.select((p) => p.isMediaCardWide(style.name)),
        );
        final feedData = ref.watch(homeSectionFeedProvider(section));

        return HorizontalSection<UnifiedMedia>(
          title: section.title,
          height: style.getLayout(isWideMode: isWide).height,
          onMoreTap: () => context.pushDiscover(
            category: section.title,
            type: section.mediaType,
            source: section.sourceInfo?.id,
          ),
          data: feedData,
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
    }
  }
}
