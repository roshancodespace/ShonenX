import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/models/anime/page_model.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/helpers/provider.dart';

class SeeAllScreen extends ConsumerStatefulWidget {
  final String title;
  final String path;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  ConsumerState<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends ConsumerState<SeeAllScreen> {
  late final AnimeProvider _animeProvider;
  // final _uuid = const Uuid();

  bool _isLoading = true;
  int _currentPage = 1;
  SearchPage _page = SearchPage();

  @override
  void initState() {
    super.initState();
    _animeProvider = getAnimeProvider(ref)!;
    _fetchData();
  }

  Future<void> _fetchData([int? pageNumber]) async {
    if (_isLoading) return; // Prevent multiple fetch calls
    setState(() => _isLoading = true);

    try {
      final page =
          await _animeProvider.getPage(widget.path, pageNumber ?? _currentPage);
      if (page.results.isEmpty && _currentPage > 1) {
        // If no results and not on the first page, go back to the first page
        setState(() {
          _currentPage = 1;
        });
        _fetchData(1); // Fetch data for the first page
        return;
      }
      setState(() {
        _page = page;
        _currentPage = pageNumber ?? _currentPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load anime');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Flexible(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed:
                  _currentPage > 1 ? () => _fetchData(_currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 8),
            _buildPageNumbers(),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _currentPage < _page.totalPages!
                  ? () => _fetchData(_currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNumbers() {
    final totalPages = _page.totalPages;
    const maxVisiblePages = 4;

    List<int> getVisiblePages() {
      if (totalPages! <= maxVisiblePages) {
        return List.generate(totalPages, (i) => i + 1);
      }

      final pages = <int>[];
      final middlePage = maxVisiblePages ~/ maxVisiblePages;

      if (_currentPage <= middlePage + 1) {
        // Near the start
        pages.addAll(List.generate(maxVisiblePages, (i) => i + 1));
      } else if (_currentPage >= totalPages - middlePage) {
        // Near the end
        pages.addAll(List.generate(
            maxVisiblePages, (i) => totalPages - maxVisiblePages + i + 1));
      } else {
        // In the middle
        for (var i = _currentPage - middlePage;
            i <= _currentPage + middlePage;
            i++) {
          pages.add(i);
        }
      }
      return pages;
    }

    final visiblePages = getVisiblePages();
    final showStartEllipsis =
        totalPages! > maxVisiblePages && visiblePages.first > 1;
    final showEndEllipsis =
        totalPages > maxVisiblePages && visiblePages.last < totalPages;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStartEllipsis) ...[
          _pageButton(1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('...'),
          ),
        ],
        ...visiblePages.map(_pageButton),
        if (showEndEllipsis) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('...'),
          ),
          _pageButton(totalPages),
        ],
      ],
    );
  }

  Widget _pageButton(int pageNumber) {
    final isSelected = pageNumber == _currentPage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isSelected ? null : () => _fetchData(pageNumber),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              pageNumber.toString(),
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_page.results.isEmpty) {
      return Center(
        child: Text(
          'No anime found',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _page.results.length,
      itemBuilder: (context, index) {
        // final tag = _uuid.v4();
        // final anime = _page.results[index];

        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            // onTap: () => navigateToDetail(context, anime, tag),
            borderRadius: BorderRadius.circular(8),
            // child: AnimeCard(
            //   anime: anime,
            //   tag: tag,
            // ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _fetchData(1),
                    child: _buildGrid(),
                  ),
                ),
                _buildPaginationControls(),
              ],
            ),
    );
  }
}
