import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/constants/constants.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/widgets/anime/anime_card.dart';
import 'package:shonenx/widgets/ui/search_bar.dart';
import 'package:uuid/uuid.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  final String? keyword;
  const BrowseScreen({super.key, this.keyword});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late TextEditingController _searchController;
  // String _lastSearch = '';
  List<Media>? _searchResults = [];
  // int _currentPage = 1;
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
      setState(() {});
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
              fontWeight: FontWeight.w700
            ),
            messageTextStyle: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      );
      return;
    }

    setState(() {
      // _lastSearch = _searchController.text;
      // _currentPage = 1;
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
              // Search Bar
              Searchbar(
                controller: _searchController,
                onSearch: _onSearch,
                onClear: onClear,
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
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults?.length,
      itemBuilder: (context, index) {
        final tag = Uuid().v4();
        return GestureDetector(
          onTap: () => navigateToDetail(context, _searchResults![index], tag),
          child: AnimeCard(
            anime: _searchResults![index],
            tag: tag,
          ),
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
            "Categories",
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
}
