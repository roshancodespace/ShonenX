import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/library_row.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/tracker_error_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/discovery_tracker_error_provider.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
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
  final double? borderRadius;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(borderRadius ?? GlobalUI.uiRoundness);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(8),
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasShownOutageSheet = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSections = ref.watch(homeFeedSectionsProvider);

    ref.listen<DiscoveryTrackerErrorInfo?>(discoveryTrackerErrorProvider, (
      previous,
      next,
    ) {
      if (next != null &&
          (previous?.trackerType != next.trackerType ||
              !_hasShownOutageSheet) &&
          mounted) {
        _hasShownOutageSheet = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            TrackerErrorSheet.show(
              context,
              failedTracker: next.trackerType,
              error: next.error,
            );
          }
        });
      } else if (next == null) {
        _hasShownOutageSheet = false;
      }
    });

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _hasShownOutageSheet = false;
          ref.read(discoveryTrackerErrorProvider.notifier).clear();
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
          cacheExtent: 500,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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

            // Tracker Outage Alert Banner
            Consumer(
              builder: (context, ref, _) {
                final trackerError = ref.watch(discoveryTrackerErrorProvider);
                if (trackerError == null) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: _TrackerOutageBanner(
                      trackerType: trackerError.trackerType,
                      isAuto: trackerError.isAuto,
                      error: trackerError.error,
                    ),
                  ),
                );
              },
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = activeSections[index];
                    return _KeepAliveSection(
                      key: ValueKey(section.id),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildSectionWidget(context, ref, section),
                      ),
                    );
                  },
                  findChildIndexCallback: (Key key) {
                    if (key is ValueKey<String>) {
                      final index = activeSections.indexWhere(
                        (s) => s.id == key.value,
                      );
                      return index == -1 ? null : index;
                    }
                    return null;
                  },
                  childCount: activeSections.length,
                ),
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
                  borderRadius: uiRoundness,
                  onTap: () => DiscoveryModeSheet.show(context),
                  icon: isTracker
                      ? Icons.cloud_outlined
                      : Icons.extension_outlined,
                  active: isTracker,
                );
              },
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              tooltip: 'Airing Calendar',
              borderRadius: uiRoundness,
              onTap: () => context.pushCalendar(),
              icon: Icons.calendar_month_outlined,
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              tooltip: 'Settings',
              borderRadius: uiRoundness,
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
        final metadataTracker = ref.watch(metadataSourceProvider);

        return HorizontalSection<UnifiedMedia>(
          title: section.title,
          height: style.getLayout(isWideMode: isWide).height,
          onMoreTap: () => context.pushDiscover(
            category: section.title,
            type: section.mediaType,
            source: section.sourceInfo?.id,
          ),
          data: feedData,
          errorBuilder: (context, error, st) {
            return _DiscoverySectionErrorWidget(
              height: style.getLayout(isWideMode: isWide).height,
              sectionTitle: section.title,
              trackerType: section.sourceInfo != null
                  ? null
                  : metadataTracker.type,
              error: error,
            );
          },
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

class _KeepAliveSection extends StatefulWidget {
  final Widget child;
  const _KeepAliveSection({super.key, required this.child});

  @override
  State<_KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<_KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _TrackerOutageBanner extends ConsumerWidget {
  final TrackerType trackerType;
  final bool isAuto;
  final Object error;

  const _TrackerOutageBanner({
    required this.trackerType,
    required this.isAuto,
    required this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = ref.watch(themePrefsProvider.select((s) => s.uiRoundness));
    final radius = BorderRadius.circular(r);

    return Material(
      color: cs.errorContainer.withValues(alpha: 0.2),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => TrackerErrorSheet.show(
          context,
          failedTracker: trackerType,
          error: error,
        ),
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              trackerType.getIconWidget(size: 20, color: cs.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trackerType.displayName} service is unavailable',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      TrackerErrorSheet.extractErrorMessage(
                        error,
                        trackerType.displayName,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: radius),
                ),
                onPressed: () => DiscoveryModeSheet.show(context),
                child: const Text('Switch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverySectionErrorWidget extends ConsumerWidget {
  final double height;
  final String sectionTitle;
  final TrackerType? trackerType;
  final Object error;

  const _DiscoverySectionErrorWidget({
    required this.height,
    required this.sectionTitle,
    required this.trackerType,
    required this.error,
  });

  void _switchSource({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onApply,
    required Widget icon,
    required String label,
    required double roundness,
  }) {
    onApply();
    ref.read(discoveryTrackerErrorProvider.notifier).clear();
    ref.invalidate(homeSectionFeedProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text('Switched discovery source to $label'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundness),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuickButton({
    required BuildContext context,
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    required BorderRadius borderRadius,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final r = ref.watch(themePrefsProvider.select((s) => s.uiRoundness));
    final chipRadius = BorderRadius.circular(r * 0.75);

    final tracker = trackerType;
    final trackerName = tracker?.displayName ?? 'Tracker';
    final errorText = TrackerErrorSheet.extractErrorMessage(error, trackerName);

    final prefs = ref.watch(discoveryPrefsProvider);
    final isAuto = prefs.metadataTrackerId == null;
    final primaryTracker = ref.watch(primaryTrackerProvider);
    final primaryType = primaryTracker.type;

    final otherTrackers = ref
        .watch(availableTrackersProvider)
        .where((t) => t.type != tracker && t.type != TrackerType.local)
        .toList();

    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tracker != null)
                tracker.getIconWidget(size: 28, color: cs.error)
              else
                Icon(Icons.cloud_off_rounded, size: 28, color: cs.error),
              const SizedBox(height: 6),
              Text(
                errorText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  if (!isAuto)
                    _buildQuickButton(
                      context: context,
                      borderRadius: chipRadius,
                      icon: Icon(
                        Icons.sync_rounded,
                        size: 14,
                        color: cs.primary,
                      ),
                      label: 'Auto (${primaryType.displayName})',
                      onTap: () => _switchSource(
                        context: context,
                        ref: ref,
                        onApply: () => ref
                            .read(discoveryPrefsProvider.notifier)
                            .setMetadataTrackerId(null),
                        icon: const Icon(
                          Icons.sync_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: 'Auto (${primaryType.displayName})',
                        roundness: r,
                      ),
                    ),
                  ...otherTrackers.map((t) {
                    final TrackerType type = t.type;
                    return _buildQuickButton(
                      context: context,
                      borderRadius: chipRadius,
                      icon: type.getIconWidget(size: 14, color: cs.primary),
                      label: type.displayName,
                      onTap: () => _switchSource(
                        context: context,
                        ref: ref,
                        onApply: () => ref
                            .read(discoveryPrefsProvider.notifier)
                            .setMetadataTrackerId(type.id),
                        icon: type.getIconWidget(size: 16, color: Colors.white),
                        label: type.displayName,
                        roundness: r,
                      ),
                    );
                  }),
                  _buildQuickButton(
                    context: context,
                    borderRadius: chipRadius,
                    icon: Icon(
                      Icons.extension_rounded,
                      size: 14,
                      color: cs.secondary,
                    ),
                    label: 'Extensions',
                    onTap: () => _switchSource(
                      context: context,
                      ref: ref,
                      onApply: () => ref
                          .read(discoveryPrefsProvider.notifier)
                          .setMode(MetadataMode.source),
                      icon: const Icon(
                        Icons.extension_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: 'Extensions',
                      roundness: r,
                    ),
                  ),
                  _buildQuickButton(
                    context: context,
                    borderRadius: chipRadius,
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    label: 'Options',
                    onTap: () => TrackerErrorSheet.show(
                      context,
                      failedTracker: tracker,
                      error: error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
