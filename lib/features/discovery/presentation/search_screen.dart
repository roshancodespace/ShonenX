import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? query;
  final MediaType type;
  const SearchScreen({super.key, this.query, this.type = MediaType.ANIME});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    if (widget.query != null) {
      ref
          .read(searchProvider.notifier)
          .search(widget.query!, type: widget.type);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = GoRouterState.of(context).topRoute?.name == 'search';

    if (!isVisible && _focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.unfocus();
      });
    }

    final searchState = ref.watch(searchProvider);

    return AppScaffold(
      title: 'Discover',
      subtitle: 'Find your next obsession',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            SearchBar(
              controller: _searchController,
              autoFocus: true,
              focusNode: _focusNode,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              leading: const Icon(Icons.search),
              hintText: 'Search anime titles...',
              onSubmitted: (value) {
                ref.read(searchProvider.notifier).search(value);
              },
            ),

            const SizedBox(height: 10),

            Expanded(
              child: searchState.when(
                loading: () => const Center(child: CircularProgressIndicator()),

                error: (e, _) => Center(child: Text(e.toString())),

                data: (result) {
                  if (result == null || result.items.isEmpty) {
                    return const Center(child: Text("No results"));
                  }

                  return Consumer(
                    builder: (context, ref, child) {
                      final style = ref.watch(
                        uiPrefsProvider.select((s) => s.cardStyle),
                      );

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: style.layout.width + 10,
                          mainAxisExtent: style.layout.height,
                          childAspectRatio: style.layout.aspectRatio,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: result.items.length + 5,
                        itemBuilder: (context, index) {
                          if (index >= result.items.length) {
                            return const SizedBox.shrink();
                          }

                          final media = result.items[index];

                          return MediaCard(
                            tag: 'search-${media.id}',
                            title: media.title.availableTitle,
                            imageUrl: media.cover ?? media.banner ?? '',
                            onTap: () => context.push(
                              '/details/${media.type.id}?tag=search-${media.id}',
                              extra: media,
                            ),
                            style: style,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
