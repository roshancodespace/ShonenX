import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/tabs/about_tab.dart';
import 'package:shonenx/features/comments/presentation/widgets/comments_tab.dart';
import 'package:shonenx/features/discovery/presentation/widgets/tabs/episodes_tab.dart';
import 'package:shonenx/features/discovery/providers/details_provider.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/presentation/widgets/edit_tracker_sheet.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_manager_sheet.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class DetailsScreen extends ConsumerStatefulWidget {
  final String tag;
  final MediaType mediaType;
  final UnifiedMedia media;
  final int initialTabIndex;
  final Object? autoPlayMode;

  const DetailsScreen({
    super.key,
    required this.tag,
    required this.mediaType,
    required this.media,
    this.initialTabIndex = 0,
    this.autoPlayMode,
  });

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final FocusNode _keyboardFocusNode;
  double _pullProgress = 0.0;
  double _accumulatedOverscroll = 0.0;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final pixels = notification.metrics.pixels;

    if (notification is OverscrollNotification &&
        notification.metrics.extentBefore == 0 &&
        notification.overscroll < 0) {
      _accumulatedOverscroll += -notification.overscroll;
      final progress = (_accumulatedOverscroll / 180.0).clamp(0.0, 1.0);
      if (progress != _pullProgress) {
        setState(() => _pullProgress = progress);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (pixels < 0) {
        final progress = (-pixels / 180.0).clamp(0.0, 1.0);
        if (progress != _pullProgress) {
          setState(() => _pullProgress = progress);
        }
      } else if (_pullProgress > 0 || _accumulatedOverscroll > 0) {
        _accumulatedOverscroll = 0.0;
        if (_pullProgress != 0.0) setState(() => _pullProgress = 0.0);
      }
    } else if (notification is ScrollEndNotification) {
      final shouldTrigger = _pullProgress >= 1.0;
      _accumulatedOverscroll = 0.0;
      if (_pullProgress != 0.0) {
        setState(() => _pullProgress = 0.0);
      }
      if (shouldTrigger) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCommentsSheet(context, widget.media);
        });
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _keyboardFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLinkPrimaryTracker();
      if (!mounted) return;
      if (widget.autoPlayMode is PlayerMode) {
        context.push('/player', extra: widget.autoPlayMode);
      } else if (widget.autoPlayMode is ReaderModeOnline) {
        context.push('/reader', extra: widget.autoPlayMode);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keyboardFocusNode.dispose();

    super.dispose();
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
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    final displayMedia =
        detailsState.value?.merge(widget.media) ?? widget.media;

    return AppScaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Stack(
          children: [
            NestedScrollView(
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
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(),
                            ),
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
                                        borderRadius: BorderRadius.circular(
                                          uiRoundness,
                                        ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            style: textTheme.labelLarge
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${displayMedia.episodes ?? '?'} ${widget.mediaType == MediaType.MANGA ? 'CHPS' : 'EPS'} | ${displayMedia.status?.toUpperCase() ?? 'UNKNOWN'}',
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
                    _CommentsAppBarButton(
                      media: displayMedia,
                      uiRoundness: uiRoundness,
                    ),
                    const SizedBox(width: 4),
                    _TrackerAppBarButton(
                      media: displayMedia,
                      uiRoundness: uiRoundness,
                    ),
                  ],
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  AboutTabWidget(
                    media: displayMedia,
                    onEpisodesTabRequested: () => _tabController.animateTo(1),
                    uiRoundness: uiRoundness,
                  ),
                  EpisodesTabWidget(media: displayMedia),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: Offset(0, _pullProgress > 0.05 ? 0.0 : -3.0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _pullProgress > 0.05 ? 1.0 : 0.0,
                    child: IgnorePointer(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: _pullProgress,
                                strokeWidth: 3.5,
                                backgroundColor: theme
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation(
                                  _pullProgress >= 1.0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              _pullProgress >= 1.0
                                  ? Icons.forum_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              color: _pullProgress >= 1.0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is! KeyDownEvent) {
              return;
            }

            switch (event.logicalKey) {
              case LogicalKeyboardKey.digit1:
                _tabController.animateTo(0);
                break;
              case LogicalKeyboardKey.digit2:
                _tabController.animateTo(1);
                break;
              case LogicalKeyboardKey.digit3:
                _showCommentsSheet(context, displayMedia);
                break;
            }
          },
          child: TabBar(
            dividerHeight: 0,
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            textScaler: const TextScaler.linear(1.15),
            tabs: [
              const Tab(text: 'About'),
              Tab(
                text: widget.mediaType == MediaType.MANGA
                    ? 'Chapters'
                    : 'Episodes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackerAppBarButton extends ConsumerWidget {
  final UnifiedMedia media;
  final double uiRoundness;

  const _TrackerAppBarButton({required this.media, required this.uiRoundness});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final activeTrackers = ref.watch(activeTrackersProvider(media.type));

    if (activeTrackers.isEmpty) return const SizedBox.shrink();

    final trackerLinksAsync = ref.watch(trackerLinkProvider(media.id));
    final tracker = ref.watch(primaryTrackerProvider);

    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(tracker.type, media.id, media.type)),
    );

    return _buildUI(
      context,
      ref,
      theme,
      tracker,
      trackingState,
      trackerLinksAsync,
      uiRoundness,
    );
  }

  Widget _buildUI(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    TrackingService tracker,
    AsyncValue<TrackedListItem?> trackingState,
    AsyncValue<Map<TrackerType, TrackerMapping>> trackerLinksAsync,
    double uiRoundness,
  ) {
    return trackingState.when(
      loading: () => _buildButton(
        theme,
        label: 'Loading...',
        icon: Icons.hourglass_empty,
        isEnabled: false,
        uiRoundness: uiRoundness,
      ),
      error: (err, stack) => _buildButton(
        theme,
        label: 'Sync Error',
        icon: Icons.sync_problem,
        onPressed: () => _openManager(context),
        uiRoundness: uiRoundness,
      ),
      data: (listItem) {
        final links = trackerLinksAsync.value ?? {};
        final isTrackerLinked = links.containsKey(tracker.type);
        final isAuthenticated = tracker.type.isAuthenticated(ref);

        String label = 'Add Tracker';
        IconData icon = Icons.add;

        if (!isAuthenticated) {
          label = 'Login to ${tracker.type.displayName}';
          icon = Icons.login;
        } else if (isTrackerLinked || tracker.type == TrackerType.local) {
          if (listItem != null) {
            label =
                '${media.type == MediaType.MANGA ? "Ch" : "Ep"} ${listItem.progress.toInt()} • ${listItem.status.getLabelForMedia(media.type)}';
            icon = Icons.bookmark_added;
          } else {
            label = 'Add to ${tracker.type.displayName}';
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
          onPressed: () {
            if (tracker is RemoteTracker && !isAuthenticated) {
              ref.read(authTokensProvider.notifier).login(tracker);
              return;
            }
            _openManager(context);
          },
          onLongPress: (isTrackerLinked && listItem != null)
              ? () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => EditTrackerSheet(
                    media: media,
                    initialItem: listItem,
                    tracker: tracker,
                  ),
                )
              : null,
          uiRoundness: uiRoundness,
        );
      },
    );
  }

  Widget _buildButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required double uiRoundness,
    bool isEnabled = true,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(uiRoundness),
          ),
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

  void _openManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TrackerManagerSheet(media: media),
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

class _CommentsAppBarButton extends StatelessWidget {
  final UnifiedMedia media;
  final double uiRoundness;

  const _CommentsAppBarButton({required this.media, required this.uiRoundness});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: IconButton.filledTonal(
        tooltip: 'Discussion',
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(uiRoundness),
          ),
        ),
        icon: const Icon(Icons.forum_rounded, size: 18),
        onPressed: () => _showCommentsSheet(context, media),
      ),
    );
  }
}

void _showCommentsSheet(BuildContext context, UnifiedMedia media) {
  AppBottomSheet.show(
    context: context,
    title: 'Discussion',
    contentPadding: EdgeInsets.zero,
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: CommentsTabWidget(media: media),
    ),
  );
}
