import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/library/providers/library_view_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/screens/tv_home_screen.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_backdrop_background.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TvLibraryScreen extends ConsumerStatefulWidget {
  const TvLibraryScreen({super.key});

  @override
  ConsumerState<TvLibraryScreen> createState() => _TvLibraryScreenState();
}

class _TvLibraryScreenState extends ConsumerState<TvLibraryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final viewState = ref.read(libraryViewStateProvider);
      final primaryTracker = ref.read(
        trackingPrefsProvider.select((s) => s.primaryTracker),
      );
      final isCloudLoggedIn =
          ref.read(trackerProfileProvider)[primaryTracker] != null;
      final isCloud =
          viewState.mode == LibraryMode.cloud &&
          primaryTracker != TrackerType.local &&
          isCloudLoggedIn;

      if (isCloud) {
        ref
            .read(
              cloudLibraryProvider((
                status: viewState.status,
                trackerType: null,
                mediaType: viewState.mediaType,
              )).notifier,
            )
            .loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final padding = context.tvPadding;
    final viewState = ref.watch(libraryViewStateProvider);
    final dynamicLibrary = ref.watch(dynamicLibraryProvider);

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final isCloudLoggedIn =
        ref.watch(trackerProfileProvider)[primaryTracker.type] != null;
    final canToggleCloud =
        primaryTracker.type != TrackerType.local && isCloudLoggedIn;

    final supportedMediaTypes = primaryTracker.supportedMediaTypes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const TvBackdropBackground(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  18,
                  padding.right,
                  14,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context,
                        cs,
                        viewState,
                        supportedMediaTypes,
                        canToggleCloud,
                        dynamicLibrary.value?.length,
                      ),
                      const SizedBox(height: 14),
                      _buildStatusPills(context, cs, viewState),
                    ],
                  ),
                ),
              ),
              _buildContentSliver(
                context,
                cs,
                viewState,
                dynamicLibrary,
                padding,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme cs,
    LibraryViewState viewState,
    List<MediaType> supportedMediaTypes,
    bool canToggleCloud,
    int? itemCount,
  ) {
    final radius = GlobalUI.uiRoundness;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.video_library_rounded, size: 26, color: cs.primary),
        const SizedBox(width: 10),
        const Text(
          'Library',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        if (itemCount != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(
                (radius * 0.4).clamp(0.0, double.infinity),
              ),
            ),
            child: Text(
              '$itemCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (supportedMediaTypes.length > 1)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(
                (radius * 0.6).clamp(0.0, double.infinity),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: supportedMediaTypes.map((type) {
                final isSelected = viewState.mediaType == type;
                final isAnime = type == MediaType.ANIME;
                return AppFocusHover(
                  onTap: () {
                    ref
                        .read(libraryViewStateProvider.notifier)
                        .setMediaType(type);
                  },
                  builder: (context, isFocused, isHovered) {
                    final active = isFocused || isHovered;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (active ? Colors.white : cs.primary)
                            : (active
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.transparent),
                        borderRadius: BorderRadius.circular(
                          ((radius * 0.6) - 2).clamp(0.0, double.infinity),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAnime
                                ? Icons.tv_rounded
                                : Icons.menu_book_rounded,
                            size: 14,
                            color: isSelected
                                ? (active ? Colors.black : cs.onPrimary)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAnime ? 'Anime' : 'Manga',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (active ? Colors.black : cs.onPrimary)
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        if (canToggleCloud) ...[
          const SizedBox(width: 12),
          AppFocusHover(
            onTap: () {
              final newMode = viewState.mode == LibraryMode.cloud
                  ? LibraryMode.local
                  : LibraryMode.cloud;
              ref.read(libraryViewStateProvider.notifier).setMode(newMode);
            },
            builder: (context, isFocused, isHovered) {
              final active = isFocused || isHovered;
              final isCloud = viewState.mode == LibraryMode.cloud;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(
                    (radius * 0.5).clamp(0.0, double.infinity),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCloud ? Icons.cloud_done_rounded : Icons.folder_rounded,
                      size: 15,
                      color: active ? Colors.black : cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCloud ? 'Cloud' : 'Local',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStatusPills(
    BuildContext context,
    ColorScheme cs,
    LibraryViewState viewState,
  ) {
    final radius = GlobalUI.uiRoundness;
    final isManga = viewState.mediaType == MediaType.MANGA;
    final statuses = TrackedStatus.values
        .where((s) => s != TrackedStatus.unknown)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: statuses.map((status) {
          final isSelected = viewState.status == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AppFocusHover(
              onTap: () {
                ref.read(libraryViewStateProvider.notifier).setStatus(status);
              },
              builder: (context, isFocused, isHovered) {
                final active = isFocused || isHovered;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (active ? Colors.white : cs.primary)
                        : (active
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.06)),
                    borderRadius: BorderRadius.circular(
                      (radius * 0.5).clamp(0.0, double.infinity),
                    ),
                    border: Border.all(
                      color: isFocused
                          ? Colors.white
                          : (isSelected
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.1)),
                      width: isFocused ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    status.getLabel(isManga),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? (active ? Colors.black : cs.onPrimary)
                          : (active ? Colors.white : Colors.white70),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentSliver(
    BuildContext context,
    ColorScheme cs,
    LibraryViewState viewState,
    AsyncValue<List<LibraryEntry>> dynamicLibrary,
    EdgeInsets padding,
  ) {
    return dynamicLibrary.when(
      loading: () => SliverPadding(
        padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 40),
        sliver: SliverToBoxAdapter(
          child: Skeletonizer(
            enabled: true,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 175,
                childAspectRatio: 0.62,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
              ),
              itemCount: 14,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      error: (err, _) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load library: $err',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              AppFocusHover(
                onTap: () {
                  final primaryTracker = ref.read(
                    trackingPrefsProvider.select((s) => s.primaryTracker),
                  );
                  final isCloudLoggedIn =
                      ref.read(trackerProfileProvider)[primaryTracker] != null;
                  final isCloud =
                      viewState.mode == LibraryMode.cloud &&
                      primaryTracker != TrackerType.local &&
                      isCloudLoggedIn;

                  if (isCloud) {
                    ref
                        .read(
                          cloudLibraryProvider((
                            status: viewState.status,
                            trackerType: null,
                            mediaType: viewState.mediaType,
                          )).notifier,
                        )
                        .refresh();
                  } else {
                    ref.invalidate(
                      localLibraryListProvider((
                        status: viewState.status,
                        mediaType: viewState.mediaType,
                      )),
                    );
                  }
                },
                builder: (context, isFocused, isHovered) {
                  final active = isFocused || isHovered;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white10,
                      borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          final isManga = viewState.mediaType == MediaType.MANGA;
          final label = viewState.status.getLabel(isManga);
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 48,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No items in $label',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Track titles or bookmark them to see them here.',
                    style: TextStyle(fontSize: 13, color: Colors.white38),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 40),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 175,
              childAspectRatio: 0.62,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = entries[index];
              final mediaType = entry.type != null
                  ? MediaType.fromId(entry.type!)
                  : viewState.mediaType;
              final isAnime = mediaType == MediaType.ANIME;
              final unit = isAnime ? 'Ep' : 'Ch';
              final watched = entry.episodesWatched;
              final total = entry.episodes;

              double? progressFraction;
              String? progressText;

              if (watched > 0) {
                if (total != null && total > 0) {
                  progressFraction = (watched / total).clamp(0.0, 1.0);
                  progressText = '$unit $watched/$total';
                } else {
                  progressText = '$unit $watched';
                }
              }

              final cardTag =
                  'tv-lib-${viewState.status.id}-${entry.providerId}-$index';

              return _TvLibraryCard(
                entry: entry,
                progressFraction: progressFraction,
                progressText: progressText,
                onFocused: () {
                  final media = entry.toUnifiedMedia();
                  final backdrop =
                      (media.banner != null && media.banner!.isNotEmpty)
                      ? media.banner
                      : entry.cover;
                  if (backdrop?.isNotEmpty == true) {
                    ref
                        .read(tvFocusedBackdropProvider.notifier)
                        .setBackdrop(backdrop);
                  }
                },
                onTap: () {
                  context.pushDetails(
                    mediaType: mediaType,
                    media: entry.toUnifiedMedia(),
                    tag: cardTag,
                  );
                },
              );
            }, childCount: entries.length),
          ),
        );
      },
    );
  }
}

class _TvLibraryCard extends StatelessWidget {
  final LibraryEntry entry;
  final double? progressFraction;
  final String? progressText;
  final VoidCallback onFocused;
  final VoidCallback onTap;

  const _TvLibraryCard({
    required this.entry,
    this.progressFraction,
    this.progressText,
    required this.onFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return AppFocusHover(
      scaleFactor: 1.05,
      onTap: onTap,
      onFocusChange: (focused) {
        if (focused) onFocused();
      },
      onHoverChange: (hovered) {
        if (hovered) onFocused();
      },
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: isFocused
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.2),
                    width: isFocused ? 2.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: active ? 0.6 : 0.2),
                      blurRadius: active ? 16 : 6,
                      offset: Offset(0, active ? 5 : 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    (radius - 1).clamp(0.0, double.infinity),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TvSmartImage(imageUrl: entry.cover, fit: BoxFit.cover),
                      if (entry.score != null && entry.score! > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(
                                (radius * 0.4).clamp(0.0, double.infinity),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  entry.score!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (entry.format != null && entry.format!.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(
                                (radius * 0.4).clamp(0.0, double.infinity),
                              ),
                            ),
                            child: Text(
                              entry.format!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      if (progressText != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (progressFraction != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: progressFraction,
                                      minHeight: 3.5,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        cs.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  progressText!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active ? cs.primary : cs.onSurface,
              ),
            ),
            if (entry.year != null || entry.status != null)
              Text(
                [
                  if (entry.year != null) '${entry.year}',
                  if (entry.status != null) entry.status!,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        );
      },
    );
  }
}
