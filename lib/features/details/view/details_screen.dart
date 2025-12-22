import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';
import 'package:shonenx/features/details/view/widgets/episodes_tab.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'widgets/widgets.dart';

class AnimeDetailsScreen extends ConsumerStatefulWidget {
  final Media anime;
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
  late Media _anime;
  bool _isWatchLoading = false;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _anime = widget.anime;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    if (widget.forceFetch) {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final repo = ref.read(animeRepositoryProvider);
      final fullDetails =
          await repo.getAnimeDetails(widget.anime.id?.toInt() ?? 0);
      if (fullDetails != null) {
        if (mounted) {
          setState(() => _anime = fullDetails);
        }
      }
    } catch (e) {
      // Handle error or just keep showing partial data
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditListBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditListBottomSheet(anime: _anime),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading overlay or indicator if fetching detailed info?
    // User requested "immediately tell the screen... and fetch".
    // We can show partial data while fetching, or a loader.
    // Showing partial data is better UX. We can show a small linear progress indicator if loading.

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final useMangayomi = ref.watch(
        experimentalProvider.select((exp) => exp.useMangayomiExtensions));

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            DetailsHeader(
              anime: _anime,
              tag: widget.tag,
              onEditPressed: _showEditListBottomSheet,
            ),
          ];
        },
        body: _isLoadingDetails
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // About Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
                    child: DetailsContent(anime: _anime),
                  ),
                  // Episodes Tab
                  EpisodesTab(
                    mediaId: widget.anime.id.toString(),
                    mediaTitle: widget.anime.title!,
                    mediaFormat: widget.anime.format!,
                    mediaCover: widget.anime.coverImage?.large ??
                        widget.anime.coverImage?.medium ??
                        '',
                  ),
                  // Characters Tab
                  const SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Center(
                      child: Text('Characters Tab Content'),
                    ),
                  ),
                ],
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
                  final progress = repo.getProgress(_anime.id.toString());
                  return FloatingActionButton.extended(
                    heroTag: 'watch_btn',
                    onPressed: _isWatchLoading
                        ? null
                        : () async {
                            setState(() => _isWatchLoading = true);
                            await providerAnimeMatchSearch(
                              context: context,
                              ref: ref,
                              animeMedia: _anime,
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
