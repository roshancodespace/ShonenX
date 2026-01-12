import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';

import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/shared/widgets/app_scale.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final small = screenWidth < 600;
    final scale = AppScaleScope.of(context);
    final cardStyle = ref.watch(uiSettingsProvider).cardStyle;
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);
    final height = cardConfigs[mode]!.responsiveHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        SizedBox(height: 8 * scale),
        SizedBox(
          height: (small ? height.small : height.large) * scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            cacheExtent: 10000 * scale,
            itemCount: mediaList.length,
            separatorBuilder: (_, __) => SizedBox(width: 12 * scale),
            itemBuilder: (context, index) {
              final media = mediaList[index];
              final id = generateId();
              final tag = id.toString() + (media.id.toString());
              return AnimatedAnimeCard(
                anime: media,
                tag: tag,
                onTap: () =>
                    navigateToDetail(context, media, tag, forceFetch: true),
                mode: mode,
              );
            },
          ),
        ),
        SizedBox(height: 24 * scale),
      ],
    );
  }
}
