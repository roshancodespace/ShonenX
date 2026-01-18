import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/anime_spotlight_card.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';

class SpotlightSection extends ConsumerStatefulWidget {
  final List<UniversalMedia>? spotlightAnime;

  const SpotlightSection({super.key, required this.spotlightAnime});

  @override
  ConsumerState<SpotlightSection> createState() => _SpotlightSectionState();
}

class _SpotlightSectionState extends ConsumerState<SpotlightSection> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final trendingAnimes =
        widget.spotlightAnime ?? List<UniversalMedia?>.filled(9, null);
    final carouselHeight = MediaQuery.of(context).size.width > 900
        ? 520.0
        : 260.0;
    final cardMode = ref.watch(
      uiSettingsProvider.select((ui) => ui.spotlightCardStyle),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SpotlightHeader(spotlightAnime: widget.spotlightAnime),
        CarouselSlider.builder(
          carouselController: _controller,
          options: CarouselOptions(
            height: carouselHeight,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enableInfiniteScroll: true,
            enlargeCenterPage: true,
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            viewportFraction: MediaQuery.of(context).size.width > 900
                ? 0.8
                : 0.9,
            pageSnapping: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          itemCount: trendingAnimes.length,
          itemBuilder: (context, index, realIndex) {
            final anime = trendingAnimes[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
              child: AnimeSpotlightCard(
                onTap: (media) => anime?.id != null
                    ? navigateToDetail(
                        context,
                        media,
                        anime?.id.toString() ?? '',
                        forceFetch: true,
                      )
                    : null,
                anime: anime,
                mode: SpotlightCardMode.values.firstWhere(
                  (e) => e.name == cardMode,
                ),
                heroTag: 'spotlight_${anime?.id ?? 'loading_$index'}',
              ),
            );
          },
        ),
        _DotIndicator(
          length: trendingAnimes.length,
          currentIndex: _currentIndex,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SpotlightHeader extends StatelessWidget {
  final List<UniversalMedia>? spotlightAnime;

  const _SpotlightHeader({required this.spotlightAnime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              'Trending ${spotlightAnime?.length ?? 0}',
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

class _DotIndicator extends StatelessWidget {
  final int length;
  final int currentIndex;

  const _DotIndicator({required this.length, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
