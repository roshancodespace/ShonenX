import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/providers/anilist/anilist_medialist_provider.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';
import 'package:shonenx/widgets/anime/anime_card.dart';
import 'package:uuid/uuid.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'CURRENT');
final cardLoadingProvider =
    StateProvider.family<bool, String>((ref, id) => false);

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final categories = {
    'CURRENT': 'Watching',
    'COMPLETED': 'Completed',
    'PAUSED': 'Paused',
    'DROPPED': 'Dropped',
    'PLANNING': 'Planning',
    'FAVORITES': 'Favorites',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAndWarn();
      ref.read(animeListProvider.notifier).fetchAllAnimeLists();
    });
  }

  Future<void> _checkUserAndWarn() async {
    final userState = ref.read(userProvider);
    if (userState != null) return;
    if (!mounted) return;

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Feature Locked',
        message: 'Anilist is required to use this feature. Please sign in.',
        contentType: ContentType.warning,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final animeListState = ref.watch(animeListProvider);
    final userState = ref.watch(userProvider);

    return Scaffold(
      body: userState == null
          ? _buildLoginPrompt()
          : _buildMainContent(selectedCategory, animeListState),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Access Your Anime Collection",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sign in with Anilist to track and manage your anime watchlist.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.push('/settings/profile'),
                    icon: const Icon(Iconsax.login),
                    label: const Text("Sign In"),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
      String selectedCategory, AnimeListState animeListState) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(selectedCategory),
        SliverToBoxAdapter(
          child: _buildCategorySelector(selectedCategory),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: _buildAnimeGrid(selectedCategory, animeListState),
        ),
      ],
    );
  }

  Widget _buildAppBar(String selectedCategory) {
    return SliverAppBar.large(
      pinned: true,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          categories[selectedCategory] ?? '',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        expandedTitleScale: 1.8,
      ),
    );
  }

  Widget _buildCategorySelector(String selectedCategory) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final entry = categories.entries.elementAt(index);
          final isSelected = selectedCategory == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilledButton.tonal(
                onPressed: () {
                  ref.read(selectedCategoryProvider.notifier).state = entry.key;
                },
                style: FilledButton.styleFrom(
                  foregroundColor: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ).copyWith(
                  elevation: isSelected
                      ? WidgetStateProperty.all(4)
                      : WidgetStateProperty.all(0),
                ),
                child: Text(entry.value),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimeGrid(String status, AnimeListState animeListState) {
    if (animeListState.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final animeList = _getAnimeList(status, animeListState);

    if (animeList.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(status, animeListState),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            childAspectRatio: 0.7,
            crossAxisSpacing: 15.0,
            mainAxisSpacing: 15.0,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final anime = animeList[index];
              final tag = Uuid().v4();
              return GestureDetector(
                onTap: () => navigateToDetail(context, anime, tag),
                child: AnimeCard(
                  tag: tag,
                  anime: anime,
                ),
              );
            },
            childCount: animeList.length,
          ),
        );
      },
    );
  }

  List<Media> _getAnimeList(String status, AnimeListState animeListState) {
    if (status == 'FAVORITES') {
      return animeListState.favorites;
    }

    final mediaListGroups = animeListState.mediaListGroups[status];
    if (mediaListGroups != null) {
      return mediaListGroups
          .expand((group) => group.entries)
          .map((e) => e.media)
          .toList();
    }
    return [];
  }

  // int _calculateCrossAxisCount(double width) {
  //   if (width <= 400) {
  //     return 3; // Small screens
  //   } else if (width <= 700) {
  //     return 3; // Medium screens
  //   } else if (width <= 1000) {
  //     return 7; // Large screens
  //   } else {
  //     return 8; // Extra large screens
  //   }
  // }

  Widget _buildEmptyState(String status, AnimeListState animeListState) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            "No anime in ${categories[status]?.toLowerCase()}",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Start exploring and add some anime to your collection!",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          if (animeListState.errors[status] != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(animeListProvider.notifier)
                    .fetchAnimeListByStatus(status);
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ],
      ),
    );
  }
}
