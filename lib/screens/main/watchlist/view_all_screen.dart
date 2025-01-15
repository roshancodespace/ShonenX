import 'package:flutter/material.dart';
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

class _ViewAllScreenState extends State<ViewAllScreen> {
  final Set<String> _selectedIds = {};
  bool _isMultiselectMode = false;

  void _onLongPress(BaseAnimeCard item) {
    setState(() {
      _isMultiselectMode = true;
      _selectedIds.add(item.id);
    });
  }

  void _onCardTap(BaseAnimeCard item) {
    if (_isMultiselectMode) {
      setState(() {
        if (_selectedIds.contains(item.id)) {
          _selectedIds.remove(item.id);
        } else {
          _selectedIds.add(item.id);
        }

        // Exit multiselect mode if no items are selected
        if (_selectedIds.isEmpty) {
          _isMultiselectMode = false;
        }
      });
    }
  }

  void _exitMultiselectMode() {
    setState(() {
      _isMultiselectMode = false;
      _selectedIds.clear();
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

      // Refresh the state
      setState(() {
        // Remove deleted items from the list
        widget.items.removeWhere((item) => _selectedIds.contains(item.id));
        _exitMultiselectMode();
      });

      if (!mounted) return;
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${idsToDelete.length} item(s) removed successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove items: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    final itemCount = _selectedIds.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
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
          title: _isMultiselectMode
              ? Text(
                  '${_selectedIds.length} Selected',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  widget.title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
          leading: _isMultiselectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitMultiselectMode,
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
          actions: [
            if (_isMultiselectMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _showDeleteConfirmationDialog,
              ),
          ],
        ),
        body: widget.items.isEmpty
            ? Center(
                child: Text(
                  "No items found in ${widget.title}",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3,mainAxisExtent: 180, mainAxisSpacing: 15, crossAxisSpacing: 10),
                  // gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  //   maxCrossAxisExtent: 200,
                  //   mainAxisExtent: 260,
                  //   mainAxisSpacing: 20,
                  //   crossAxisSpacing: 15,
                  // ),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isSelected = _selectedIds.contains(item.id);
      
                    return GestureDetector(
                      onLongPress: () => _onLongPress(item),
                      onTap: () => _onCardTap(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: _isMultiselectMode && isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimeCard(
                              anime: item,
                              tag: 'view_all',
                            ),
                            if (_isMultiselectMode && isSelected)
                              Positioned.fill(
                                child: Container(
                                  color:
                                      theme.colorScheme.primary.withOpacity(0.3),
                                  child: Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedTick02,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
