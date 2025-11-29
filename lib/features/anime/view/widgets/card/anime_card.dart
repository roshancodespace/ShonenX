import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';

class AnimatedAnimeCard extends StatefulWidget {
  final Media anime;
  final String tag;
  final VoidCallback? onTap;
  final AnimeCardMode mode;

  const AnimatedAnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onTap,
    this.mode = AnimeCardMode.defaults,
  });

  @override
  State<AnimatedAnimeCard> createState() => _AnimatedAnimeCardState();
}

class _AnimatedAnimeCardState extends State<AnimatedAnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 1. Get the configuration for the current mode
    final config = cardConfigs[widget.mode]!;

    // 2. Get screen width once for responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // 3. Use the config to determine size
    final width = isSmallScreen
        ? config.responsiveWidth.small
        : config.responsiveWidth.large;
    final height = isSmallScreen
        ? config.responsiveHeight.small
        : config.responsiveHeight.large;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          height: height,
          margin: EdgeInsets.only(
            top: _isHovered ? 0 : 4,
            bottom: _isHovered ? 4 : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(config.radius),
            // boxShadow: [
            //   BoxShadow(
            //     color: Theme.of(context)
            //         .colorScheme
            //         .shadow
            //         .withOpacity(_isHovered ? 0.25 : 0.1),
            //     blurRadius: 8,
            //     offset: const Offset(0, 2),
            //   ),
            // ],
          ),
          child: config.builder(
            anime: widget.anime,
            tag: widget.tag,
            isHovered: _isHovered,
          ),
        ),
      ),
    );
  }
}
