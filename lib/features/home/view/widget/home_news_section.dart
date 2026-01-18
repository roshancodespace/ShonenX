import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/news/view/news_screen.dart';
import 'package:shonenx/features/news/view/widgets/news_card.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';

class HomeNewsSection extends ConsumerWidget {
  const HomeNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    final theme = Theme.of(context);

    return newsAsync.when(
      skipLoadingOnReload: true,
      data: (newsList) {
        if (newsList.isEmpty) return const SizedBox.shrink();

        final displayList = newsList.take(7).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest News', style: theme.textTheme.titleLarge),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: 'View All News',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final news = displayList[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: NewsCard(news: news),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
