import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/widgets/anime_card.dart';

class ViewAllScreen extends StatefulWidget {
  final String title;
  final List<BaseAnimeCard> items;
  final WatchlistBox watchlistBox;

  const ViewAllScreen({
    super.key,
    required this.title,
    required this.items,
    required this.watchlistBox,
  });

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedIds = {};
  bool _isMultiselectMode = false;
  late AnimationController _filterController;
  String _searchQuery = '';
  late List<BaseAnimeCard> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filteredItems = List.from(widget.items); // Optimize initialization
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      _filteredItems = widget.items
          .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _performDeletion() async {
    final idsToDelete = _selectedIds.toList();
    final title = widget.title.toLowerCase();

    try {
      if (title.contains('recently')) {
        await widget.watchlistBox.removeRecentlyWatched(idsToDelete);
      } else if (title.contains('favorites')) {
        await widget.watchlistBox.removeFavorites(idsToDelete);
      }

      setState(() {
        _filteredItems.removeWhere((item) => _selectedIds.contains(item.id));
        _exitMultiselectMode();
      });

      if (!mounted) return;
      _showSnackBar('${idsToDelete.length} item(s) removed successfully');
    } catch (e) {
      _showSnackBar('Failed to remove items: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red : null,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final itemCount = _selectedIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete $itemCount Item${itemCount > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Text(
          'Are you sure you want to remove the ${itemCount > 1 ? 'selected items' : 'item'}?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeletion();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exitMultiselectMode() {
    setState(() {
      _isMultiselectMode = false;
      _selectedIds.clear();
      _filterController.reverse();
    });
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isMultiselectMode ? 0 : 60,
      child: SingleChildScrollView(
        child: TextField(
          onChanged: _filterItems,
          decoration: InputDecoration(
            hintText: 'Search ${widget.title}...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 375),
          columnCount: (MediaQuery.of(context).size.width ~/ 150).toInt(),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _buildAnimeCard(_filteredItems[index]),
            ),
          ),
        );
      },
    );
  }

  void _onLongPress(BaseAnimeCard item) {
    setState(() {
      _isMultiselectMode = true;
      _toggleSelection(item);
    });
  }

  void _toggleSelection(BaseAnimeCard item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
        if (_selectedIds.isEmpty) {
          _exitMultiselectMode();
        }
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _sortItems() {
    setState(() {
      _filteredItems.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _onCardTap(BaseAnimeCard item) {
    if (_isMultiselectMode) {
      _toggleSelection(item);
    } else {
      // Handle single tap if needed
    }
  }

  Widget _buildAnimeCard(BaseAnimeCard item) {
    final isSelected = _selectedIds.contains(item.id);

    return Card(
      child: InkWell(
        onLongPress: () => _onLongPress(item),
        onTap: () => _onCardTap(item),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimeCard(
              anime: item,
              tag: 'view_all',
              disableInteraction: _isMultiselectMode,
            ),
            if (_isMultiselectMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.4)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          width: 3,
                        )
                      : null,
                  borderRadius: (Theme.of(context).cardTheme.shape
                          as RoundedRectangleBorder)
                      .borderRadius,
                ),
                child: isSelected
                    ? Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedTick02,
                          size: 40,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      maintainBottomViewPadding: true,
      child: Scaffold(
        appBar: AppBar(
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isMultiselectMode
                ? Text(
                    '${_selectedIds.length} Selected',
                    key: const ValueKey('selected'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Hero(
                    tag: widget.title,
                    child: Text(
                      widget.title,
                      key: const ValueKey('title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          leading: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: HugeIcon(
                icon: _isMultiselectMode
                    ? HugeIcons.strokeRoundedCancel01
                    : HugeIcons.strokeRoundedArrowLeft01,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
                key: ValueKey(_isMultiselectMode),
              ),
            ),
            onPressed: _isMultiselectMode
                ? _exitMultiselectMode
                : () => Navigator.pop(context),
          ),
          actions: [
            if (!_isMultiselectMode) ...[
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _sortItems,
              ),
            ],
            if (_isMultiselectMode)
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete01,
                  color: _selectedIds.isNotEmpty
                      ? theme.colorScheme.onSurface
                      : Colors.grey,
                ),
                onPressed: _selectedIds.isNotEmpty
                    ? _showDeleteConfirmationDialog
                    : null,
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? "No items found in ${widget.title}"
                                  : "No results found for '$_searchQuery'",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _buildGridView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
