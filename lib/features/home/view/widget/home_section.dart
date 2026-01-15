import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/misc.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final small = screenWidth < 600;

    final cardStyle = ref.watch(uiSettingsProvider).cardStyle;
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);
    final height = cardConfigs[mode]!.responsiveHeight;

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
          height: small ? height.small : height.large,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaList[index];
              final tag = randomId();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedAnimeCard(
                  anime: media,
                  tag: tag,
                  mode: mode,
                  onTap: () =>
                      navigateToDetail(context, media, tag, forceFetch: true),
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
