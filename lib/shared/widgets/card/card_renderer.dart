import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

import 'models/card_config.dart';
import 'styles/cinematic_card.dart';
import 'styles/classic_card.dart';
import 'styles/compact_card.dart';
import 'styles/editorial_card.dart';
import 'styles/expressive_card.dart';
import 'styles/material_card.dart';
import 'styles/minimal_card.dart';
import 'styles/neon_card.dart';
import 'styles/wide_banner_card.dart';

class CardRenderer extends StatelessWidget {
  final MediaCardStyle style;
  final CardConfig config;

  const CardRenderer({super.key, required this.style, required this.config});

  @override
  Widget build(BuildContext context) {
    final Widget card = switch (style) {
      MediaCardStyle.classic => ClassicCard(config: config),
      MediaCardStyle.minimal => MinimalCard(config: config),
      MediaCardStyle.expressive => ExpressiveCard(config: config),
      MediaCardStyle.material => MaterialCard(config: config),
      MediaCardStyle.cinematic => CinematicCard(config: config),
      MediaCardStyle.neon => NeonCard(config: config),
      MediaCardStyle.compact => CompactCard(config: config),
      MediaCardStyle.editorial => EditorialCard(config: config),
      MediaCardStyle.wideBanner => WideBannerCard(config: config),
    };

    return RepaintBoundary(child: card);
  }
}
