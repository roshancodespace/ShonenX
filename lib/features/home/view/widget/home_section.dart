import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';

class HomeSectionWidget extends ConsumerWidget {
  final String title;
  final List<Media> mediaList;

  const HomeSectionWidget({
    super.key,
    required this.title,
    required this.mediaList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final small = screenWidth < 600;
    final cardStyle = ref.watch(uiSettingsProvider).cardStyle;
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);
    final height = cardConfigs[mode]!.responsiveHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: small ? height.small : height.large,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: mediaList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final media = mediaList[index];
              final id = generateId();
              final tag = id.toString() + (media.id.toString());
              return AnimatedAnimeCard(
                anime: media,
                tag: tag,
                onTap: () => navigateToDetail(context, media, tag),
                mode: mode,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
