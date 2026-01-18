import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';
import 'package:shonenx/features/news/view/widgets/news_card.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('News'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(newsProvider.notifier).refresh(),
        child: newsAsync.when(
          skipLoadingOnReload: true,
          data: (newsList) {
            if (newsList.isEmpty) {
              return const Center(child: Text('No news available.'));
            }
            return Column(
              children: [
                if (newsAsync.isLoading) const LinearProgressIndicator(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      return NewsCard(news: newsList[index]);
                    },
                  ),
                ),
              ],
            );
          },
          error: (err, stack) => Center(child: Text('Error: $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
