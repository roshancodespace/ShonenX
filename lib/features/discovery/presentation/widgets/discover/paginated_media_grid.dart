import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PaginatedMediaGrid extends ConsumerWidget {
  final AsyncValue<PaginatedResult<UnifiedMedia>?> state;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final VoidCallback onAutoLoad;
  final double paddingTop;

  const PaginatedMediaGrid({
    super.key,
    required this.state,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onAutoLoad,
    this.paddingTop = 80,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return state.when(
      loading: () => Skeletonizer(
        enabled: true,
        child: GridView.builder(
          padding: EdgeInsets.only(bottom: 200, top: paddingTop),
          gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
            minCrossAxisExtent: style.layout.width,
            childAspectRatio: style.layout.aspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            return MediaCard(
              tag: 'skeleton-grid-$index',
              title: 'Placeholder Media Title Name',
              imageUrl: '',
              style: style,
              format: 'TV',
              score: 8.5,
              year: '2026',
              onTap: () {},
            );
          },
        ),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (result) {
        if (result == null || result.items.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scrollController.hasClients) {
            return;
          }

          final position = scrollController.position;

          if (position.maxScrollExtent == 0 &&
              result.hasNextPage &&
              !isLoadingMore) {
            onAutoLoad();
          }
        });

        return Stack(
          children: [
            GridView.builder(
              controller: scrollController,
              padding: EdgeInsets.only(bottom: 200, top: paddingTop),
              gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
                minCrossAxisExtent: style.layout.width,
                childAspectRatio: style.layout.aspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: result.items.length,
              itemBuilder: (context, index) {
                final media = result.items[index];

                return MediaCard(
                  tag: 'media-${media.id}',
                  format: media.format,
                  score: media.score,
                  status: media.status,
                  genres: media.genres,
                  year: media.season,
                  title: media.title.availableTitle,
                  imageUrl: media.cover ?? media.banner ?? '',
                  style: style,
                  onTap: () {
                    context.pushDetails(
                      mediaType: media.type,
                      media: media,
                      tag: 'media-${media.id}',
                    );
                  },
                );
              },
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: isLoadingMore ? 80 : -60,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }
}
