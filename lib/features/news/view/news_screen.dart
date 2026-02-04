import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';
import 'package:shonenx/features/news/view/widgets/news_card.dart';
import 'package:shonenx/features/news/view/widgets/news_compact_card.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  String _viewMode = 'grid'; // grid, list, compact

  @override
  void initState() {
    super.initState();
    _viewMode = sharedPrefs.getString('news_view_mode') ?? 'grid';
  }

  void _setViewMode(String mode) {
    setState(() => _viewMode = mode);
    sharedPrefs.setString('news_view_mode', mode);
  }

  void _cycleViewMode() {
    String newMode;
    switch (_viewMode) {
      case 'grid':
        newMode = 'list';
        break;
      case 'list':
        newMode = 'compact';
        break;
      case 'compact':
        newMode = 'grid';
        break;
      default:
        newMode = 'grid';
    }
    _setViewMode(newMode);
  }

  IconData _getViewModeIcon() {
    switch (_viewMode) {
      case 'grid':
        return Icons.grid_on;
      case 'list':
        return Icons.table_rows_outlined;
      case 'compact':
        return Icons.view_list_outlined;
      default:
        return Iconsax.grid_1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('News'),
        actions: [
          IconButton(
            onPressed: _cycleViewMode,
            icon: Icon(_getViewModeIcon()),
            tooltip: 'Switch View Mode',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(newsProvider.notifier).refresh(),
        child: newsAsync.when(
          skipLoadingOnReload: true,
          data: (newsList) {
            if (newsList.isEmpty) {
              return const Center(child: Text('No news available.'));
            }

            if (_viewMode == 'grid') {
              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  return NewsCard(news: newsList[index]);
                },
              );
            } else if (_viewMode == 'compact') {
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  return NewsCompactCard(news: newsList[index]);
                },
              );
            } else {
              // List View
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: newsList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: 250,
                    child: NewsCard(news: newsList[index]),
                  );
                },
              );
            }
          },
          error: (err, stack) => Center(child: Text('Error: $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
