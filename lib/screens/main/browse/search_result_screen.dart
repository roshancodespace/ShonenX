import 'package:flutter/material.dart';
import 'package:nekoflow/data/models/search_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/anime_card.dart';

class SearchResultScreen extends StatefulWidget {
  final SearchModel searchModel;
  final AnimeService animeService;
  final String searchType;

  const SearchResultScreen({
    super.key,
    required this.searchModel,
    required this.animeService,
    this.searchType = 'query',
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  bool _isGridLayout = true;
  bool _isLoading = false;
  List<AnimeResult> _animeResults = [];
  int _currentPage = 1;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animeResults = widget.searchModel.animes;
    _currentPage = widget.searchModel.currentPage;
    _totalPages = widget.searchModel.totalPages;
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_currentPage < _totalPages) {
        _loadPage(_currentPage + 1);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SearchModel updatedSearchModel;
      if (widget.searchType == 'query') {
        updatedSearchModel = await widget.animeService
            .fetchByQuery(query: widget.searchModel.searchQuery, page: page);
      } else {
        final genreDetail = await widget.animeService
            .fetchGenreAnime(widget.searchModel.searchQuery, page: page);

        updatedSearchModel = SearchModel(
          currentPage: genreDetail.data.currentPage,
          hasNextPage: genreDetail.data.hasNextPage,
          totalPages: genreDetail.data.totalPages,
          searchQuery: widget.searchModel.searchQuery,
          searchFilters: {},
          animes: genreDetail.data.animes
              .map((genreAnime) => AnimeResult(
                    id: genreAnime.id,
                    name: genreAnime.name,
                    poster: genreAnime.poster,
                    duration: genreAnime.duration,
                    type: genreAnime.type,
                    rating: genreAnime.rating,
                    episodes: genreAnime.episodes,
                  ))
              .toList(),
          mostPopularAnimes: [],
        );
      }

      setState(() {
        _animeResults = updatedSearchModel.animes;
        _currentPage = updatedSearchModel.currentPage;
        _totalPages = updatedSearchModel.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load page: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleLayout() {
    setState(() {
      _isGridLayout = !_isGridLayout;
    });
  }

  Widget _buildPaginationIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.first_page),
            onPressed: _currentPage > 1 ? () => _loadPage(1) : null,
          ),
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed:
                _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: _currentPage < _totalPages
                ? () => _loadPage(_currentPage + 1)
                : null,
          ),
          IconButton(
            icon: Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages
                ? () => _loadPage(_totalPages)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeData.colorScheme.surface,
        leading: BackButton(color: themeData.colorScheme.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.searchModel.searchQuery,
              style: themeData.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeData.colorScheme.onSurface,
              ),
            ),
            Text(
              '${_animeResults.length} results found',
              style: themeData.textTheme.bodySmall?.copyWith(
                color: themeData.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridLayout ? Icons.view_list : Icons.grid_view,
              color: themeData.colorScheme.primary,
            ),
            onPressed: _toggleLayout,
            tooltip:
                _isGridLayout ? 'Switch to List View' : 'Switch to Grid View',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPage(1),
              child: _isGridLayout
                  ? _buildGridView(themeData)
                  : _buildListView(themeData),
            ),
          ),
          _buildPaginationIndicator(),
        ],
      ),
    );
  }

  Widget _buildGridView(ThemeData themeData) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
      ),
      itemCount: _animeResults.length,
      itemBuilder: (context, index) {
        final anime = _animeResults[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimeCard(
            anime: anime,
            tag: 'search_grid_$index',
          ),
        );
      },
    );
  }

  Widget _buildListView(ThemeData themeData) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _animeResults.length,
      itemExtent: 140,
      itemBuilder: (context, index) {
        final anime = _animeResults[index];
        return AnimeCard(
          anime: anime,
          tag: 'search_list_$index',
          isListLayout: true,
        );
      },
    );
  }
}
