import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/details/view_model/details_page_notifier.dart';
import 'package:shonenx/features/details/view/widgets/episodes_tab.dart';
import 'package:shonenx/features/details/view/widgets/characters_tab.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final useMangayomi = ref.watch(
      experimentalProvider.select((exp) => exp.useMangayomiExtensions),
    );

    final id = widget.anime.id;
    final pageState = ref.watch(detailsPageProvider(id));
    final displayedAnime = pageState.details.value ?? widget.anime;
    final isLoading = pageState.details.isLoading;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            DetailsHeader(
              anime: displayedAnime,
              tag: widget.tag,
              onEditPressed: () => _showEditListBottomSheet(displayedAnime),
            ),
          ];
        },
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
      bottomNavigationBar: Material(
        color: colorScheme.surface,
        elevation: 8,
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
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
      floatingActionButton: !useMangayomi
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
