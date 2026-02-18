import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';

import 'package:shonenx/shared/providers/settings/ui_notifier.dart';
import 'package:shonenx/shared/ui/shonenx_gridview.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:go_router/go_router.dart';

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
    final mode = ref.watch(uiSettingsProvider).cardStyle;
    final size = mode.getDimensions(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.title),
      ),
      body: _items.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ShonenXGridView(
              padding: const EdgeInsets.all(10),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              crossAxisExtent: size.width,
              childAspectRatio: size.width / size.height,
              itemCount: _items.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final media = _items[index];
                return GestureDetector(
                  onTap: () =>
                      navigateToDetail(context, media, 'section_${media.id}'),
                  child: AnimeCard(
                    anime: media,
                    mode: mode,
                    tag: 'section_${media.id}',
                  ),
                );
              },
            ),
    );
  }
}
