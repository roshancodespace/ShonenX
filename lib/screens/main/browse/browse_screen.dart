import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nekoflow/data/models/search_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/screens/main/browse/search_result_screen.dart';
import 'package:nekoflow/widgets/search_bar.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static const List<String> _genres = [
    "Action", "Adventure", "Cars", "Comedy", "Dementia", "Demons", 
    "Drama", "Ecchi", "Fantasy", "Game", "Harem", "Historical", 
    "Horror", "Isekai", "Josei", "Kids", "Magic", "Martial Arts", 
    "Mecha", "Military", "Music", "Mystery", "Parody", "Police", 
    "Psychological", "Romance", "Samurai", "School", "Sci-Fi", 
    "Seinen", "Shoujo", "Shoujo Ai", "Shounen", "Shounen Ai", 
    "Slice of Life", "Space", "Sports", "Super Power", 
    "Supernatural", "Thriller", "Vampire"
  ];

  late AnimeService _animeService;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animeService = AnimeService();
  }

  Future<void> _performSearch({int page = 1}) async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a search query.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null; // Clear previous error
    });

    try {
      final result = await _animeService.fetchByQuery(
        query: _searchController.text,
        page: page,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => SearchResultScreen(
            searchModel: result,
            animeService: _animeService,
            searchType: 'query',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'An error occurred. Please check your connection or try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGenreAnimes({
    required String genreName, 
    int page = 1
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Transform genre name to URL-friendly format
      final formattedGenreName = genreName
        .toLowerCase()
        .split(' ')
        .join('-');

      final genreDetail = await _animeService.fetchGenreAnime(
        formattedGenreName,
        page: page
      );

      if (!mounted) return;

      if (genreDetail.success) {
        // Map GenreDetailModel's AnimeResult to SearchModel's AnimeResult
        final searchResult = SearchModel(
          currentPage: genreDetail.data.currentPage,
          hasNextPage: genreDetail.data.hasNextPage,
          totalPages: genreDetail.data.totalPages,
          searchQuery: formattedGenreName, // Use formatted genre name
          searchFilters: {}, 
          animes: genreDetail.data.animes.map((genreAnime) => AnimeResult(
            id: genreAnime.id,
            name: genreAnime.name,
            poster: genreAnime.poster,
            duration: genreAnime.duration,
            type: genreAnime.type,
            rating: genreAnime.rating,
            episodes: genreAnime.episodes,
          )).toList(),
          mostPopularAnimes: [], 
        );

        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => SearchResultScreen(
              searchModel: searchResult,
              animeService: _animeService,
              searchType: 'genre',
            ),
          ),
        );
      } else {
        setState(() {
          _error = 'Failed to fetch genre anime. Please try again later.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error fetching genre anime. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar( backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,toolbarHeight: 0,),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Searchbar(
                controller: _searchController,
                onSearch: () => _performSearch(),
                isLoading: _isLoading,
              ),
            ),
          ),

          // Error Message Display
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  _error!,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Genre Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse by Genre',
                    style: themeData.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore anime across different genres',
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Genres List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final genre = _genres[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Material(
                      color: themeData.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _fetchGenreAnimes(genreName: genre),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                genre,
                                style: themeData.textTheme.titleMedium,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: themeData.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _genres.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}