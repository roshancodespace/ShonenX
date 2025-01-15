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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
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
        if (page == 1) {
          _animeResults = updatedSearchModel.animes;
        } else {
          _animeResults.addAll(updatedSearchModel.animes);
        }
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.first_page),
            onPressed: _currentPage > 1 ? () => _loadPage(1) : null,
          ),
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  '$_currentPage / $_totalPages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () => _loadPage(_currentPage + 1) : null,
          ),
          IconButton(
            icon: Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages ? () => _loadPage(_totalPages) : null,
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Search Results",
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '"${widget.searchModel.searchQuery}"',
              style: themeData.textTheme.bodySmall?.copyWith(
                color: themeData.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridLayout ? Icons.view_list : Icons.grid_view,
              color: themeData.colorScheme.onSurface,
            ),
            onPressed: _toggleLayout,
            tooltip: _isGridLayout ? 'Switch to List View' : 'Switch to Grid View',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${_animeResults.length} results found',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _animeResults.length,
      itemBuilder: (context, index) {
        final anime = _animeResults[index];
        return AnimeCard(
          anime: anime,
          tag: 'search_grid_$index',
        );
      },
    );
  }

  Widget _buildListView(ThemeData themeData) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _animeResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
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
