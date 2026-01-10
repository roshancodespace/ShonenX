import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/details/view_model/details_provider.dart';
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
  bool _isWatchLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Trigger background fetch silently
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = _getAnimeId(widget.anime);
      ref.read(detailsProvider(id).notifier).init(widget.anime);
    });
  }

  int _getAnimeId(UniversalMedia media) {
    if (int.tryParse(media.id) != null) {
      return int.parse(media.id);
    }
    return 0; // Or handle error
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
        builder: (_) => AnimeDetailsScreen(
          anime: media,
          tag: 'tag-${media.id}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final useMangayomi = ref.watch(
        experimentalProvider.select((exp) => exp.useMangayomiExtensions));

    final id = _getAnimeId(widget.anime);
    final detailsAsync = ref.watch(detailsProvider(id));

    // Use the latest data if available, otherwise fallback to widget.anime
    final displayedAnime = detailsAsync.value ?? widget.anime;
    final isLoading = detailsAsync.isLoading;

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
              // About Tab
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
                child: DetailsContent(
                  anime: displayedAnime,
                  isLoading: isLoading,
                  onMediaTap: _onMediaTap,
                ),
              ),
              // Episodes Tab
              EpisodesTab(
                mediaId: displayedAnime.id.toString(),
                mediaTitle: displayedAnime.title,
                mediaFormat: displayedAnime.format ?? '',
                mediaCover: displayedAnime.coverImage.large ??
                    displayedAnime.coverImage.medium ??
                    '',
              ),
              // Characters Tab
              CharactersTab(
                characters: displayedAnime.characters,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
      // Bottom Tab Bar - cleaner design
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
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Watch Now Button (extended)
                Consumer(builder: (context, ref, child) {
                  final repo = ref.watch(watchProgressRepositoryProvider);
                  final progress =
                      repo.getProgress(displayedAnime.id.toString());
                  return FloatingActionButton.extended(
                    heroTag: 'watch_btn',
                    onPressed: _isWatchLoading
                        ? null
                        : () async {
                            setState(() => _isWatchLoading = true);
                            await providerAnimeMatchSearch(
                              context: context,
                              ref: ref,
                              animeMedia: displayedAnime,
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
                                  colorScheme.onPrimary),
                            ),
                          )
                        : const Icon(Iconsax.play_circle, size: 24),
                    label: Text(
                      _isWatchLoading
                          ? 'Loading...'
                          : progress?.currentEpisode != null
                              ? 'EP ${progress?.currentEpisode}'
                              : 'Watch Now',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
