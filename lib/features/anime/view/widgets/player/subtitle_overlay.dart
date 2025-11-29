import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/settings/utils/subtitle_utils.dart';
import 'package:shonenx/features/settings/view_model/subtitle_notifier.dart';

class SubtitleOverlay extends ConsumerWidget {
  const SubtitleOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleStyle = ref.watch(subtitleAppearanceProvider);
    final subtitleText =
        ref.watch(playerStateProvider.select((s) => s.subtitle.firstOrNull));

    if (subtitleText == null || subtitleText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: subtitleStyle.position == 1
            ? Alignment.bottomCenter
            : subtitleStyle.position == 2
                ? Alignment.center
                : Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(subtitleStyle.backgroundOpacity),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subtitleStyle.forceUppercase
                ? subtitleText.toUpperCase()
                : subtitleText,
            textAlign: TextAlign.center,
            style: SubtitleUtils.getSubtitleTextStyle(subtitleStyle),
          ),
        ),
      ),
    );
  }
}
