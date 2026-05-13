import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/presentation/widgets/tabs/about_tab.dart';
import 'package:shonenx/features/discovery/presentation/widgets/tabs/episodes_tab.dart';
import 'package:shonenx/features/discovery/providers/details_provider.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/presentation/widgets/edit_tracker_sheet.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_manager_sheet.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class DetailsScreen extends ConsumerStatefulWidget {
  final String tag;
  final MediaType mediaType;
  final UnifiedMedia media;

  const DetailsScreen({
    super.key,
    required this.tag,
    required this.mediaType,
    required this.media,
  });

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLinkPrimaryTracker();
    });
  }

  Future<void> _autoLinkPrimaryTracker() async {
    final prefs = ref.read(trackingPrefsProvider);
    if (!prefs.autoTrackPrimary) return;

    final primaryType = prefs.primaryTracker;
    if (primaryType == TrackerType.local) return;

    final media = widget.media;

    // Only auto-link if it's tracker-based metadata
    final isTrackerMedia = media.sourceId == null;

    if (!isTrackerMedia) return;

    String? trackingId;
    trackingId = media.id;

    final linksMap = await ref.read(trackerLinkProvider(media.id).future);
    if (linksMap.containsKey(primaryType)) return;

    final mapping = TrackerMapping()
      ..trackerId = primaryType.id
      ..trackingId = trackingId
      ..trackingTitle = media.title.availableTitle;

    ref
        .read(trackerLinkProvider(media.id).notifier)
        .saveLink(primaryType, mapping);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final detailsState = ref.watch(
      detailsProvider(
        DetailsArgs(
          widget.media.id,
          widget.mediaType,
          sourceId: widget.media.sourceId,
        ),
      ),
    );

    final displayMedia =
        detailsState.value?.merge(widget.media) ?? widget.media;

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 350.0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                background: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl:
                            displayMedia.banner ?? displayMedia.cover ?? '',
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) =>
                            const Center(child: Icon(Icons.error)),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 5),
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.5, 1],
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor.withValues(
                                alpha: 0.8,
                              ),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SizedBox(
                                width: 112,
                                child: AspectRatio(
                                  aspectRatio: 2 / 3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Hero(
                                      tag: widget.tag,
                                      child: CachedNetworkImage(
                                        imageUrl: displayMedia.cover ?? '',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              color: colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 10.0,
                                  right: 10.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayMedia.title.availableTitle,
                                      style: textTheme.titleLarge,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (displayMedia.title.native != null ||
                                        displayMedia.title.romaji != null)
                                      Text(
                                        displayMedia.title.native ??
                                            displayMedia.title.romaji ??
                                            '',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${displayMedia.episodes ?? '?'} EPS | ${displayMedia.status?.toUpperCase() ?? 'UNKNOWN'}',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 3.0,
                                      runSpacing: 3.0,
                                      alignment: WrapAlignment.start,
                                      children: [
                                        for (final genre
                                            in displayMedia.genres ?? [])
                                          Chip(
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            side: BorderSide.none,
                                            color: WidgetStatePropertyAll(
                                              colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                            labelPadding: EdgeInsets.zero,
                                            label: Text(
                                              genre,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                const _DownloadAppBarButton(),
                _TrackerAppBarButton(media: displayMedia),
              ],
            ),
          ],
          body: TabBarView(
            children: [
              AboutTabWidget(media: displayMedia),
              EpisodesTabWidget(media: displayMedia),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(
          child: TabBar(
            dividerHeight: 0,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: 'About'),
              Tab(text: 'Episodes'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackerAppBarButton extends ConsumerWidget {
  final UnifiedMedia media;

  const _TrackerAppBarButton({required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final enabledMap = ref.watch(
      trackingPrefsProvider.select((p) => p.enabledTrackers),
    );
    final availableTrackers = ref.watch(availableTrackersProvider);

    final activeTrackers = availableTrackers
        .where((t) => enabledMap[t.type] ?? true)
        .map((t) => t.type)
        .toList(growable: false);

    if (activeTrackers.isEmpty) return const SizedBox.shrink();

    final trackerLinksAsync = ref.watch(trackerLinkProvider(media.id));
    final primaryType = ref.watch(primaryTrackerProvider).type;

    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(primaryType, media.id)),
    );

    return _buildUI(
      context,
      ref,
      theme,
      primaryType,
      activeTrackers,
      trackingState,
      trackerLinksAsync,
    );
  }

  Widget _buildUI(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    TrackerType primaryType,
    List<TrackerType> activeTrackers,
    AsyncValue<TrackedListItem?> trackingState,
    AsyncValue<Map<TrackerType, TrackerMapping>> trackerLinksAsync,
  ) {
    return trackingState.when(
      loading: () => _buildButton(
        theme,
        label: 'Loading...',
        icon: Icons.hourglass_empty,
        isEnabled: false,
      ),
      error: (err, stack) => _buildButton(
        theme,
        label: 'Sync Error',
        icon: Icons.sync_problem,
        onPressed: () => _openManager(context, activeTrackers),
      ),
      data: (listItem) {
        final links = trackerLinksAsync.value ?? {};
        final isPrimaryLinked = links.containsKey(primaryType);
        final isAuthenticated = primaryType.isAuthenticated(ref);

        String label = 'Add Tracker';
        IconData icon = Icons.add;

        if (!isAuthenticated) {
          label = 'Login to ${primaryType.displayName}';
          icon = Icons.login;
        } else if (isPrimaryLinked || primaryType == TrackerType.local) {
          if (listItem != null) {
            label =
                'Ep ${listItem.progress.toInt()} • ${listItem.status.displayName}';
            icon = Icons.bookmark_added;
          } else {
            label = 'Add to ${primaryType.displayName}';
            icon = Icons.add_to_photos;
          }
        } else if (links.isNotEmpty) {
          label = 'Manage Trackers';
          icon = Icons.bookmarks;
        }

        return _buildButton(
          theme,
          label: label,
          icon: icon,
          onPressed: () => _openManager(context, activeTrackers),
          onLongPress: (isPrimaryLinked && listItem != null)
              ? () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => EditTrackerSheet(
                    media: media,
                    initialItem: listItem,
                    trackerType: primaryType,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    bool isEnabled = true,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: isEnabled ? onPressed : null,
      onLongPress: isEnabled ? onLongPress : null,
      icon: Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  void _openManager(
    BuildContext context,
    List<TrackerType> activeTrackers, [
    TrackerType? editTracker,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TrackerManagerSheet(
        media: media,
        activeTrackers: activeTrackers,
        editTracker: editTracker,
      ),
    );
  }
}

class _DownloadAppBarButton extends ConsumerWidget {
  const _DownloadAppBarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(downloadTasksProvider);
    final activeTasks =
        tasksAsync.value
            ?.where(
              (t) =>
                  t.status == DownloadStatus.downloading ||
                  t.status == DownloadStatus.pending,
            )
            .toList() ??
        [];
    final activeCount = activeTasks.length;

    if (activeCount == 0) return const SizedBox.shrink();

    double? averageProgress;
    double totalProgress = 0.0;
    int validCount = 0;
    for (final t in activeTasks) {
      if (t.progress >= 0.0) {
        totalProgress += t.progress;
        validCount++;
      }
    }
    averageProgress = validCount > 0 ? totalProgress / validCount : null;

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Badge(
        isLabelVisible: activeCount > 0,
        label: Text(activeCount.toString()),
        offset: const Offset(2, -2),
        child: IconButton(
          onPressed: () => context.push('/downloads'),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
          icon: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  value: averageProgress,
                  strokeWidth: 2.2,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.12,
                  ),
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const Icon(Icons.download_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
