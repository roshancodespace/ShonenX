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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Iconsax.video_play,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Track Your Anime Journey",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Connect with Anilist to manage your watchlist and discover new anime.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push('/settings/profile'),
                  icon: const Icon(Iconsax.login),
                  label: const Text("Connect with Anilist"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
      String selectedCategory, AnimeListState animeListState) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildAppBar(selectedCategory, innerBoxIsScrolled),
        SliverToBoxAdapter(
          child: _buildCategorySelector(selectedCategory),
        ),
      ],
      body: _buildAnimeList(selectedCategory, animeListState),
    );
  }

  Widget _buildAppBar(String selectedCategory, bool innerBoxIsScrolled) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        expandedTitleScale: 1.3,
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categories[selectedCategory] ?? '',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (!innerBoxIsScrolled) ...[
              const SizedBox(height: 4),
              Text(
                _getCategorySubtitle(selectedCategory),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.2),
                theme.colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          color: theme.colorScheme.onSurface,
          icon: const Icon(Iconsax.sort),
          tooltip: 'Sort',
          onPressed: () {
            // Implement sort functionality
          },
        ),
        IconButton(
          color: theme.colorScheme.onSurface,
          icon: const Icon(Iconsax.filter),
          tooltip: 'Filter',
          onPressed: () {
            // Implement filter functionality
          },
        ),
        IconButton(
          color: theme.colorScheme.onSurface,
          icon: const Icon(Iconsax.search_normal),
          tooltip: 'Search',
          onPressed: () {
            // Implement search functionality
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategorySelector(String selectedCategory) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final entry = categories.entries.elementAt(index);
          final isSelected = selectedCategory == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedCategoryProvider.notifier).state = entry.key;
                }
              },
              label: Text(entry.value),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimeList(String status, AnimeListState animeListState) {
    if (animeListState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final animeList = _getAnimeList(status, animeListState);

    if (animeList.isEmpty) {
      return _buildEmptyState(status, animeListState);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: animeList.length,
      itemBuilder: (context, index) {
        final anime = animeList[index];
        final tag = const Uuid().v4();
        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => navigateToDetail(context, anime, tag),
            borderRadius: BorderRadius.circular(12),
            child: AnimeCard(
              tag: tag,
              anime: anime,
            ),
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
    return mediaListGroups
            ?.expand((group) => group.entries)
            .map((e) => e.media)
            .toList() ??
        [];
  }

  Widget _buildEmptyState(String status, AnimeListState animeListState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Iconsax.video_play,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Anime Found",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start building your ${categories[status]?.toLowerCase()} list by exploring new anime!",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (animeListState.errors[status] != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(animeListProvider.notifier)
                      .fetchAnimeListByStatus(status);
                },
                icon: const Icon(Iconsax.refresh),
                label: const Text("Try Again"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategorySubtitle(String category) {
    switch (category) {
      case 'CURRENT':
        return 'Keep track of what you\'re watching';
      case 'COMPLETED':
        return 'Anime you\'ve finished watching';
      case 'PAUSED':
        return 'Taking a break from these shows';
      case 'DROPPED':
        return 'Shows you\'ve stopped watching';
      case 'PLANNING':
        return 'Your anime watchlist';
      case 'FAVORITES':
        return 'Your all-time favorite anime';
      default:
        return '';
    }
  }
}