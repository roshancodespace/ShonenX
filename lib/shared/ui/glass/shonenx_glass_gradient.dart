import 'package:flutter/material.dart';

class ShonenXGlassGradient extends StatelessWidget {
  final List<double> stops;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  const ShonenXGlassGradient({
    super.key,
    this.stops = const [0.0, 0.4, 0.7, 1.0],
    this.colors = const [],
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  const ShonenXGlassGradient.legibility({super.key})
    : stops = const [0.0, 0.4, 0.7, 1.0],
      colors = const [],
      begin = Alignment.topCenter,
      end = Alignment.bottomCenter;

  const ShonenXGlassGradient.vignette({super.key})
    : stops = const [0.0, 0.3, 0.6, 1.0],
      colors = const [
        Color(0x66000000),
        Colors.transparent,
        Color(0x33000000),
        Color(0xCC000000),
      ],
      begin = Alignment.topCenter,
      end = Alignment.bottomCenter;

  @override
  Widget build(BuildContext context) {
    if (colors.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            stops: stops,
            colors: colors,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          stops: stops,
          colors: [
            Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: isDark ? 0.8 : 0.5),
          ],
        ),
      ),
    );
  }
}
