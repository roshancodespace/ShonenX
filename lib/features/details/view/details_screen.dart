import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/details/view_model/details_page_notifier.dart';
import 'package:shonenx/features/details/view/widgets/episodes_tab.dart';
import 'package:shonenx/features/details/view/widgets/characters_tab.dart';
import 'package:shonenx/features/details/view/widgets/comments_bottom_sheet.dart';
import 'package:shonenx/core/providers/settings/experimental_notifier.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'widgets/widgets.dart';

class AnimeDetailsScreen extends ConsumerStatefulWidget {
  final UniversalMedia anime;
  final String tag;
  final bool forceFetch;

  const AnimeDetailsScreen({
    super.key,
    required this.anime,
    required this.tag,
    this.forceFetch = false,
  });

  @override
  ConsumerState<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends ConsumerState<AnimeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  double _commentPullProgress = 0;
  bool _commentSheetOpened = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.anime.id;
      ref.read(detailsPageProvider(id).notifier).init(widget.anime);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditListBottomSheet(UniversalMedia anime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditListBottomSheet(anime: anime),
    );
  }

  void _onMediaTap(UniversalMedia media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnimeDetailsScreen(anime: media, tag: 'tag-${media.id}'),
      ),
    );
  }

  bool _isTopPull = false;

  bool _handleScrollNotification(
    ScrollNotification notification,
    UniversalMedia anime,
  ) {
    // Block updates if sheet is already opening/open
    if (_commentSheetOpened) return false;

    // Remove overscroll for Episodes tab (index 1)
    if (_tabController.index == 1) return false;

    // Determine the pull direction and magnitude
    if (notification is OverscrollNotification) {
      if (notification.overscroll > 0) {
        // Bottom pull
        if (_isTopPull) {
          setState(() {
            _isTopPull = false;
            _commentPullProgress = 0;
          });
        }
        final newProgress =
            (_commentPullProgress + notification.overscroll / 250.0).clamp(
              0.0,
              1.2,
            );
        if (newProgress != _commentPullProgress) {
          setState(() => _commentPullProgress = newProgress);
        }
      } else if (notification.overscroll < 0) {
        // Top pull
        if (!_isTopPull) {
          setState(() {
            _isTopPull = true;
            _commentPullProgress = 0;
          });
        }
        // Use absolute value for progress calculation
        final newProgress =
            (_commentPullProgress + (notification.overscroll.abs()) / 250.0)
                .clamp(0.0, 1.2);
        if (newProgress != _commentPullProgress) {
          setState(() => _commentPullProgress = newProgress);
        }
      }

      if (_commentPullProgress >= 1.0 && !_commentSheetOpened) {
        _commentSheetOpened = true;
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            CommentsBottomSheet.show(context, anime).then((_) {
              if (mounted) {
                setState(() {
                  _commentSheetOpened = false;
                  _commentPullProgress = 0;
                });
              }
            });

            // Animate out the indicator after 1 second
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && _commentSheetOpened) {
                setState(() => _commentPullProgress = 0);
              }
            });
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_commentPullProgress > 0 && !_commentSheetOpened) {
        setState(() => _commentPullProgress = 0);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final useExtensions = ref.watch(
      experimentalProvider.select((exp) => exp.useExtensions),
    );

    final id = widget.anime.id;
    final pageState = ref.watch(detailsPageProvider(id));
    final displayedAnime = pageState.details.value ?? widget.anime;
    final isLoading = pageState.details.isLoading;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) => _handleScrollNotification(n, displayedAnime),
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  DetailsHeader(
                    anime: displayedAnime,
                    tag: widget.tag,
                    onEditPressed: () =>
                        _showEditListBottomSheet(displayedAnime),
                  ),
                ];
              },
              body: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _KeepAliveWrapper(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
                        child: DetailsContent(
                          anime: displayedAnime,
                          isLoading: isLoading,
                          onMediaTap: _onMediaTap,
                        ),
                      ),
                    ),
                    _KeepAliveWrapper(
                      child: EpisodesTab(
                        mediaId: displayedAnime.id.toString(),
                        mediaTitle: displayedAnime.title,
                        mediaFormat: displayedAnime.format ?? '',
                        mediaCover:
                            displayedAnime.coverImage.large ??
                            displayedAnime.coverImage.medium ??
                            '',
                      ),
                    ),
                    _KeepAliveWrapper(
                      child: CharactersTab(
                        characters: displayedAnime.characters,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Comments overscroll indicator
            Positioned(
              bottom: _isTopPull ? null : 16,
              top: _isTopPull ? MediaQuery.of(context).padding.top + 16 : null,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: _commentPullProgress <= 0,
                child: _CommentsRevealIndicator(
                  progress: _commentPullProgress,
                  isTop: _isTopPull,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: colorScheme.surface,
        elevation: 8,
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              indicatorColor: colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Episodes'),
                Tab(text: 'Characters'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: !useExtensions
          ? _WatchFab(anime: displayedAnime)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _WatchFab extends ConsumerStatefulWidget {
  final UniversalMedia anime;
  const _WatchFab({required this.anime});

  @override
  ConsumerState<_WatchFab> createState() => _WatchFabState();
}

class _WatchFabState extends ConsumerState<_WatchFab> {
  bool _isWatchLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = ref.watch(
      watchProgressRepositoryProvider.select(
        (repo) => repo.getProgress(widget.anime.id.toString()),
      ),
    );

    return FloatingActionButton.extended(
      heroTag: 'watch_btn',
      onPressed: _isWatchLoading
          ? null
          : () async {
              setState(() => _isWatchLoading = true);
              await providerAnimeMatchSearch(
                context: context,
                ref: ref,
                animeMedia: widget.anime,
              );
              if (mounted) {
                setState(() => _isWatchLoading = false);
              }
            },
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 6,
      icon: _isWatchLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Iconsax.play_circle, size: 24),
      label: Text(
        _isWatchLoading
            ? 'Loading...'
            : progress?.currentEpisode != null
            ? 'EP ${progress?.currentEpisode}'
            : 'Watch Now',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

// ─── Comments Overscroll Indicator ───────────────────────────────

class _CommentsRevealIndicator extends StatelessWidget {
  final double progress;
  final bool isTop;

  const _CommentsRevealIndicator({required this.progress, this.isTop = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0);
    final isTriggered = progress >= 1.0;

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clamped),
        duration: Duration(milliseconds: isTriggered ? 300 : 200),
        curve: isTriggered ? Curves.elasticOut : Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: isTriggered ? 1.15 : 0.7 + (value * 0.3),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isTriggered
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: clamped,
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      color: isTriggered
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      backgroundColor: colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    Icon(
                      isTriggered
                          ? Icons.chat_bubble_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 12,
                      color: isTriggered
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isTriggered
                    ? 'Opening comments...'
                    : isTop
                    ? 'Pull down for comments'
                    : 'Pull up for comments',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isTriggered
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
