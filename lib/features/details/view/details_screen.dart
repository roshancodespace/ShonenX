import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/details/view/widgets/episodes_tab.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'widgets/widgets.dart';

class AnimeDetailsScreen extends ConsumerStatefulWidget {
  final Media anime;
  final String tag;

  const AnimeDetailsScreen({super.key, required this.anime, required this.tag});

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
      builder: (context) => EditListBottomSheet(anime: widget.anime),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              anime: widget.anime,
              tag: widget.tag,
              onEditPressed: _showEditListBottomSheet,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // About Tab
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
              child: DetailsContent(anime: widget.anime),
            ),
            // Episodes Tab
            EpisodesTab(
              mediaId: widget.anime.id.toString(),
              mediaTitle: widget.anime.title!,
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
                // Fix Match (round)
                // Padding(
                //   padding: const EdgeInsets.only(right: 8),
                //   child: FloatingActionButton(
                //     heroTag: 'retry_btn',
                //     onPressed: () {
                //       // TODO: Add retry functionality later
                //     },
                //     backgroundColor: colorScheme.secondaryContainer,
                //     foregroundColor: colorScheme.onSecondaryContainer,
                //     elevation: 4,
                //     child: const Icon(Iconsax.search_normal),
                //   ),
                // ),

                // Watch Now Button (extended)
                FloatingActionButton.extended(
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
                                colorScheme.onPrimary),
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 24),
                  label: Text(
                    _isWatchLoading ? 'Loading...' : 'Watch Now',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
