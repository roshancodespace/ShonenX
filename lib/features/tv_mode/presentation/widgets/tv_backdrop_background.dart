import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/tv_mode/presentation/screens/tv_home_screen.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';

class TvBackdropBackground extends ConsumerWidget {
  final double blurSigma;

  const TvBackdropBackground({super.key, this.blurSigma = 16.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backdropUrl = ref.watch(tvFocusedBackdropProvider);

    if (backdropUrl == null || backdropUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: SizedBox.expand(
              key: ValueKey(backdropUrl),
              child: Opacity(
                opacity: 0.2,
                child: TvSmartImage(
                  imageUrl: backdropUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 720,
                  maxWidthDiskCache: 1280,
                  imageFilter: blurSigma > 0
                      ? ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma)
                      : null,
                  errorWidget: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
