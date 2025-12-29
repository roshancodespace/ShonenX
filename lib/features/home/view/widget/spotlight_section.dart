import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_spotlight_card.dart';
import 'package:shonenx/features/home/view/widget/slider_indicator.dart';
import 'package:shonenx/features/home/view/widgets/spotlight/spotlight_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';

class SpotlightSection extends ConsumerStatefulWidget {
  final List<Media>? spotlightAnime;

  const SpotlightSection({super.key, required this.spotlightAnime});

  @override
  ConsumerState<SpotlightSection> createState() => _SpotlightSectionState();
}

class _SpotlightSectionState extends ConsumerState<SpotlightSection> {
  final FlutterCarouselController _controller = FlutterCarouselController();

  @override
  Widget build(BuildContext context) {
    final trendingAnimes =
        widget.spotlightAnime ?? List<Media?>.filled(9, null);
    final carouselHeight =
        MediaQuery.of(context).size.width > 900 ? 500.0 : 240.0;
    final cardMode =
        ref.watch(uiSettingsProvider.select((ui) => ui.spotlightCardStyle));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SpotlightHeader(spotlightAnime: widget.spotlightAnime),
        Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
              final isHorizontal = pointerSignal.scrollDelta.dx != 0;
              final isVertical = pointerSignal.scrollDelta.dy != 0;

              if (isHorizontal || (isVertical && isShiftPressed)) {
                // Handle horizontal scroll for Carousel
                final delta = isHorizontal
                    ? pointerSignal.scrollDelta.dx
                    : pointerSignal.scrollDelta.dy;

                // Simple threshold to prevent over-sensitivity
                if (delta.abs() > 20) {
                  if (delta > 0) {
                    _controller.nextPage();
                  } else {
                    _controller.previousPage();
                  }
                }
              } else if (isVertical) {
                // Propagate vertical scroll to parent
                final scrollable = Scrollable.of(context);
                final newOffset =
                    scrollable.position.pixels + pointerSignal.scrollDelta.dy;
                if (newOffset >= scrollable.position.minScrollExtent &&
                    newOffset <= scrollable.position.maxScrollExtent) {
                  scrollable.position.jumpTo(newOffset);
                }
              }
            }
          },
          child: FlutterCarousel.builder(
            options: FlutterCarouselOptions(
              controller: _controller,
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
              physics: const BouncingScrollPhysics(),
            ),
            itemCount: trendingAnimes.length,
            itemBuilder: (context, index, realIndex) {
              final anime = trendingAnimes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                child: AnimeSpotlightCard(
                  onTap: (media) => anime?.id != null
                      ? navigateToDetail(
                          context, media, anime?.id.toString() ?? '',
                          forceFetch: true)
                      : null,
                  anime: anime,
                  mode: SpotlightCardMode.values
                      .firstWhere((e) => e.name == cardMode),
                  heroTag: anime?.id.toString() ?? 'loading_$index',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpotlightHeader extends StatelessWidget {
  final List<Media>? spotlightAnime;

  const _SpotlightHeader({required this.spotlightAnime});

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
