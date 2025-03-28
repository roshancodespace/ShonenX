import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/constants/constants.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/widgets/anime/anime_card_v2.dart';
import 'package:shonenx/widgets/ui/search_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:iconsax/iconsax.dart';

final sortOptionProvider =
    StateProvider<String>((ref) => 'Title'); // Shared or local sort state
final filterFormatProvider =
    StateProvider<String?>((ref) => null); // Hardcoded format filter

class BrowseScreen extends ConsumerStatefulWidget {
  final String? keyword;
  const BrowseScreen({super.key, this.keyword});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late TextEditingController _searchController;
  List<Media>? _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.keyword != null) {
      _searchController.text = widget.keyword!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.fixed,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: "Really?",
            message: "You can't search for nothing!",
            contentType: ContentType.warning,
            color: Colors.red.shade300,
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            messageTextStyle: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final animeProvider = getAnimeProvider(ref);
    final anilistService = AnilistService();
    if (animeProvider == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      _searchResults = await anilistService.searchAnime(_searchController.text);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: "Search Error",
            message: "Error occurred while searching: $error",
            contentType: ContentType.failure,
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void onClear() {
    _searchResults = [];
    _searchController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with Search Bar and Actions
              Row(
                children: [
                  Expanded(
                    child: Searchbar(
                      controller: _searchController,
                      onSearch: _onSearch,
                      onClear: onClear,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Iconsax.sort),
                    color: colorScheme.onSurface,
                    onPressed: _showSortDialog,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Iconsax.filter),
                    color: colorScheme.onSurface,
                    onPressed: _showFilterDialog,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main Content
              Expanded(
                child: _searchController.text.isNotEmpty
                    ? _isLoading
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Searching for "${_searchController.text}"',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildSearchResults()
                    : _buildDefaultContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final sortOption = ref.watch(sortOptionProvider);
    final filterFormat = ref.watch(filterFormatProvider);
    List<Media> animeList = List.from(_searchResults ?? []);

    if (animeList.isEmpty) {
      return const Center(child: Text("No results found."));
    }

    // Apply sorting
    try {
      switch (sortOption) {
        case 'Title':
          animeList.sort((a, b) =>
              (a.title?.romaji ?? '').compareTo(b.title?.romaji ?? ''));
          break;
        case 'Popularity':
          animeList
              .sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
          break;
        case 'Score':
          animeList.sort(
              (a, b) => (b.averageScore ?? 0).compareTo(a.averageScore ?? 0));
          break;
      }
    } catch (e) {
      debugPrint('Sorting error: $e');
    }

    // Apply format filter
    if (filterFormat != null && filterFormat.isNotEmpty) {
      animeList =
          animeList.where((media) => media.format == filterFormat).toList();
    }

    if (animeList.isEmpty) {
      return const Center(child: Text("No results match the filter."));
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 100), // Extra bottom padding
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: animeList.length,
      itemBuilder: (context, index) {
        final tag = Uuid().v4();
        return AnimatedAnimeCard(
          anime: animeList[index],
          tag: tag,
          onTap: () => navigateToDetail(context, animeList[index], tag),
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSection(
            "Categories \n(in development)",
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.entries
                  .map((category) => _buildCategoryButton(
                        category.key,
                        category.value,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 120), // Space for scrolling
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String path, String title) {
    return OutlinedButton(
      onPressed: () {
        context.push('/all/$path?title=$title');
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 1200) return 6;
    if (width > 800) return 6;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
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
              _buildSortOption('Popularity', currentSort, context),
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

  Widget _buildSortOption(String option, String currentSort, context) {
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
    const availableFormats = [null, 'TV', 'MOVIE', 'OVA']; // Hardcoded formats

    showDialog(
      context: context,
      builder: (context) {
        final currentFormat = ref.read(filterFormatProvider);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Filter By Format",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableFormats.length,
              itemBuilder: (context, index) {
                final format = availableFormats[index];
                return ListTile(
                  title: Text(
                    format ?? 'All Formats',
                    style: TextStyle(
                      color: format == currentFormat
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: format == currentFormat
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(filterFormatProvider.notifier).state = format;
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
