import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';

import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';

import 'package:shonenx/core/providers/settings/ui_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';

class HomeSectionWidget extends ConsumerWidget {
  final String title;
  final List<UniversalMedia> mediaList;

  const HomeSectionWidget({
    super.key,
    required this.title,
    required this.mediaList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final mode = ref.watch(uiSettingsProvider).cardStyle;
    final height = mode.getDimensions(context).height;

    if (mediaList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: ListView.builder(
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaList[index];
              final tag = 'home-$title-${media.id}';
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => navigateToDetail(context, media, tag),
                  child: AnimeCard(anime: media, tag: tag, mode: mode),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
