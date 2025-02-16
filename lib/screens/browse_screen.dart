import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/constants/constants.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/helpers/responsiveness.dart';
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
  String _lastSearch = '';
  List<Media>? _searchResults = [];
  // ignore: unused_field
  int _currentPage = 1;
  bool _isLoading = false; // Track loading state

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
          ),
        ),
      );
      return;
    }

    setState(() {
      _lastSearch = _searchController.text;
      _currentPage = 1; // Reset to first page on new search
      _isLoading = true; // Set loading state
    });

    final animeProvider = getAnimeProvider(ref);
    final anilistService = AnilistService();
    if (animeProvider == null) {
      setState(() {
        _isLoading = false; // Reset loading state
      });
      return;
    }

    try {
      _searchResults = await anilistService.searchAnime(_searchController.text);
    } catch (error) {
      if (!mounted) return;
      // Handle error (e.g., show a snackbar or dialog)
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
        _isLoading = false; // Reset loading state
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
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Searchbar(
                  controller: _searchController,
                  onSearch: () {
                    _onSearch();
                  },
                  onClear: onClear),
              const SizedBox(height: 15),
              Expanded(
                child: _searchController.text.isNotEmpty
                    ? _isLoading
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                const SizedBox(height: 10),
                                Text(
                                  'Searching for "${_searchController.text}"',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildSearchResultGrid(),
                                  const SizedBox(
                                      height: 120), // Added space for scrolling
                                ],
                              ),
                            ),
                          )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _buildGenresSection(),
                            SizedBox(
                              height: 10,
                            ),
                            _buildCategoriesSection(),
                            SizedBox(
                              height: 120,
                            )
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultGrid() {
    final size = MediaQuery.sizeOf(context);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (size.width /
                getResponsiveSize(context, mobileSize: 120, dektopSize: 180))
            .floor(),
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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

  Widget _buildCategoriesSection() {
    return _buildSection(
        "Categories",
        Wrap(
            direction: Axis.horizontal,
            runAlignment: WrapAlignment.spaceBetween,
            alignment: WrapAlignment.start,
            spacing: 8.0,
            runSpacing: 8.0,
            children: categories.entries
                .map((category) =>
                    _buildCategoryButton(category.key, category.value))
                .toList()));
  }

  Widget _buildCategoryButton(path, title) {
    return OutlinedButton(
      onPressed: () {
        context.push('/all/$path?title=$title');
      },
      child: Text(title),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
