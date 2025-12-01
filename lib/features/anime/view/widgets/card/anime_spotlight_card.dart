import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/home/view/widgets/spotlight/spotlight_card_config.dart';

class AnimeSpotlightCard extends ConsumerWidget {
  final Media? anime;
  final Function(Media)? onTap;
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
    final config = spotlightCardConfigs[mode] ??
        spotlightCardConfigs[SpotlightCardMode.defaults]!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: config.height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(config.radius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(config.radius),
        child: config.builder(
          anime: anime,
          heroTag: heroTag,
          onTap: onTap,
        ),
      ),
    );
  }
}
