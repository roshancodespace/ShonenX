import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';

class AnimeSpotlightCard extends ConsumerWidget {
  final UniversalMedia? anime;
  final Function(UniversalMedia)? onTap;
  final String heroTag;
  final SpotlightCardMode mode;

  const AnimeSpotlightCard({
    super.key,
    required this.anime,
    this.onTap,
    required this.heroTag,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = mode.radius(context);
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            if (mode.hasHardShadow)
              const BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
              )
            else
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: mode.build(anime: anime, heroTag: heroTag, onTap: onTap),
        ),
      ),
    );
  }
}
