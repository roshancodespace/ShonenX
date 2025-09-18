import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/anilist/media.dart';
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

class _AnimeDetailsScreenState extends ConsumerState<AnimeDetailsScreen> {
  late final ScrollController _scrollController;
  bool _isWatchLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              DetailsHeader(
                anime: widget.anime,
                tag: widget.tag,
                onEditPressed: _showEditListBottomSheet,
              ),
              SliverToBoxAdapter(
                child: DetailsContent(
                  anime: widget.anime,
                ),
              ),
            ],
          ),
          if (!useMangayomi)
            WatchButton(
              isLoading: _isWatchLoading,
              onPressed: () async {
                if (_isWatchLoading) return;
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
            ),
        ],
      ),
    );
  }
}
