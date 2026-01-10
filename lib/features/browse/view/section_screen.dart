import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/features/watchlist/view/widget/shonenx_gridview.dart';
import 'package:shonenx/helpers/navigation.dart';

class SectionScreen extends ConsumerStatefulWidget {
  final String title;
  final Future<List<UniversalMedia>> Function({int page, int perPage})
      fetchItems;

  const SectionScreen({
    super.key,
    required this.title,
    required this.fetchItems,
  });

  @override
  ConsumerState<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends ConsumerState<SectionScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<UniversalMedia> _items = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.fetchItems(page: _currentPage, perPage: 20);
      if (mounted) {
        setState(() {
          if (newItems.isEmpty) {
            _hasMore = false;
          } else {
            _items.addAll(newItems);
            _currentPage++;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Maybe show snackbar error?
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardStyle = ref.watch(uiSettingsProvider).cardStyle;
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);
    final width = MediaQuery.sizeOf(context).width;
    final columnCount = width >= 1400
        ? 6
        : width >= 1100
            ? 5
            : width >= 800
                ? 4
                : width >= 500
                    ? 3
                    : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _items.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ShonenXGridView(
              padding: const EdgeInsets.all(16),
              controller: _scrollController,
              crossAxisCount: columnCount,
              physics: const BouncingScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
              items: [
                ..._items.map((media) => AnimatedAnimeCard(
                      anime: media,
                      mode: mode,
                      tag: 'section_${media.id}',
                      onTap: () => navigateToDetail(
                          context, media, 'section_${media.id}'),
                    )),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}
