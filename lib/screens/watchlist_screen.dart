import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/providers/anilist/anilist_medialist_provider.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';
import 'package:shonenx/widgets/anime/anime_card_v2.dart';
import 'package:uuid/uuid.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'CURRENT');
final cardLoadingProvider =
    StateProvider.family<bool, String>((ref, id) => false);
final sortOptionProvider = StateProvider<String>((ref) => 'Title');
final filterGenreProvider = StateProvider<String?>((ref) => null);

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
        title: 'Sign In Required',
        message: 'Link Anilist to unlock your watchlist.',
        contentType: ContentType.warning,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userState = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: userState == null ? _buildLoginPrompt() : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.video_play,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                "Your Anime Awaits",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Sign in with Anilist to track your watchlist.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () =>
                    context.push('/settings/profile'), // Keep push for now
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final animeListState = ref.watch(animeListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildCategoryTabs(),
        Expanded(
          child: _buildAnimeList(selectedCategory, animeListState),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Watchlist",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -1,
                ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.sort),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () => _showSortDialog(),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Iconsax.filter),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () => _showFilterDialog(),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final entry = categories.entries.elementAt(index);
          final isSelected = selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = entry.key;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
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
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final sortOption = ref.watch(sortOptionProvider);
    final filterGenre = ref.watch(filterGenreProvider);
    List<MediaList> animeList = _getAnimeList(status, animeListState);

    if (animeList.isEmpty) {
      return _buildEmptyState(status);
    }

    // Apply sorting with null safety
    animeList =
        List.from(animeList); // Create a copy to avoid mutating original
    try {
      switch (sortOption) {
        case 'Title':
          animeList.sort((a, b) => (a.media.title?.romaji ?? '')
              .compareTo(b.media.title?.romaji ?? ''));
          break;
        case 'Progress':
          animeList.sort((a, b) => (a.progress ?? 0)
              .compareTo(b.progress ?? 0)); // Null-safe comparison
          break;
        case 'Score':
          animeList.sort((a, b) =>
              (a.score ?? 0).compareTo(b.score ?? 0)); // Null-safe comparison
          break;
      }
    } catch (e) {
      // Log error and fallback to unsorted list
      debugPrint('Sorting error: $e');
    }

    // Apply filtering
    if (filterGenre != null && filterGenre.isNotEmpty) {
      animeList = animeList
          .where((mediaList) =>
              mediaList.media.genres?.contains(filterGenre) ?? false)
          .toList();
    }

    if (animeList.isEmpty) {
      return _buildEmptyState(status);
    }

    return GridView.builder(
      padding:
          const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra 100px at bottom
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: animeList.length,
      itemBuilder: (context, index) {
        final mediaList = animeList[index];
        final tag = const Uuid().v4();
        return AnimatedAnimeCard(
          tag: tag,
          anime: mediaList.media,
          onTap: () => navigateToDetail(context, mediaList.media, tag),
        );
      },
    );
  }

  List<MediaList> _getAnimeList(String status, AnimeListState animeListState) {
    if (status == 'FAVORITES') {
      return animeListState.favorites
          .map((media) => MediaList(
                media: media,
                status: 'FAVORITES',
                score: media.averageScore?.toInt() ?? 0,
                progress: 0,
              ))
          .toList();
    }
    final mediaListGroups = animeListState.mediaListGroups[status];
    return mediaListGroups?.expand((group) => group.entries).toList() ?? [];
  }

  Widget _buildEmptyState(String status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
                child: Icon(
                  Iconsax.video_play,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Empty List",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your ${categories[status]?.toLowerCase()} list is looking lonely. Add some anime!",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final currentSort = ref.read(sortOptionProvider);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Sort By",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption('Title', currentSort, context),
              _buildSortOption('Progress', currentSort, context),
              _buildSortOption('Score', currentSort, context),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortOption(
      String option, String currentSort, BuildContext context) {
    return ListTile(
      title: Text(
        option,
        style: TextStyle(
          color: option == currentSort
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: option == currentSort
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        ref.read(sortOptionProvider.notifier).state = option;
        Navigator.pop(context);
      },
    );
  }

  void _showFilterDialog() {
    final animeListState = ref.read(animeListProvider);
    final allGenres = animeListState.mediaListGroups.values
        .expand((groups) => groups)
        .expand((group) => group.entries)
        .expand((mediaList) => mediaList.media.genres ?? [])
        .toSet()
        .toList()
      ..sort();
    final availableGenres = [null, ...allGenres];

    showDialog(
      context: context,
      builder: (context) {
        final currentGenre = ref.read(filterGenreProvider);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Filter By Genre",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableGenres.length,
              itemBuilder: (context, index) {
                final genre = availableGenres[index];
                return ListTile(
                  title: Text(
                    genre ?? 'All Genres',
                    style: TextStyle(
                      color: genre == currentGenre
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: genre == currentGenre
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(filterGenreProvider.notifier).state = genre;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
