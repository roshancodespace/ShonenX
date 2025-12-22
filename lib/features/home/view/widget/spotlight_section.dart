import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_spotlight_card.dart';
import 'package:shonenx/features/home/view/widget/slider_indicator.dart';
import 'package:shonenx/features/home/view/widgets/spotlight/spotlight_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';

class SpotlightSection extends ConsumerWidget {
  final HomePage? homePage;

  const SpotlightSection({super.key, required this.homePage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAnimes =
        homePage?.trendingAnime ?? List<Media?>.filled(9, null);
    final carouselHeight =
        MediaQuery.of(context).size.width > 900 ? 500.0 : 240.0;
    final cardMode =
        ref.watch(uiSettingsProvider.select((ui) => ui.spotlightCardStyle));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SpotlightHeader(homePage: homePage),
        FlutterCarousel(
          options: FlutterCarouselOptions(
            height: carouselHeight,
            showIndicator: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enableInfiniteScroll: true,
            floatingIndicator: false,
            enlargeCenterPage: true,
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            slideIndicator: CustomSlideIndicator(context),
            viewportFraction:
                MediaQuery.of(context).size.width > 900 ? 0.95 : 0.9,
            pageSnapping: true,
          ),
          items: trendingAnimes
              .map((anime) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                    child: AnimeSpotlightCard(
                      onTap: (media) => anime?.id != null
                          ? navigateToDetail(
                              context, media, anime?.id.toString() ?? '',
                              forceFetch: true)
                          : null,
                      anime: anime,
                      mode: SpotlightCardMode.values
                          .firstWhere((e) => e.name == cardMode),
                      heroTag: anime?.id.toString() ?? 'loading',
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SpotlightHeader extends StatelessWidget {
  final HomePage? homePage;

  const _SpotlightHeader({required this.homePage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.star5, size: 18, color: theme.colorScheme.tertiary),
            const SizedBox(width: 8),
            Text(
              'Trending ${homePage?.trendingAnime.length ?? 0}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
