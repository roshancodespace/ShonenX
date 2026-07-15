import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/universal_card_renderer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaCard extends ConsumerWidget {
  final String title;
  final String tag;
  final String? format;
  final Widget? badge;
  final String imageUrl;
  final VoidCallback onTap;
  final MediaCardStyle style;
  final Map<String, dynamic>? config;

  const MediaCard({
    super.key,
    required this.title,
    required this.tag,
    this.format,
    this.badge,
    required this.imageUrl,
    required this.onTap,
    this.style = MediaCardStyle.classic,
    this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideMode = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
    final scale = ref.watch(themePrefsProvider).uiScaleFactor;
    final layout = style.getScaledLayout(scale, isWideMode: isWideMode);

    return FocusHoverDetector(
      onTap: onTap,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap();
            return null;
          },
        ),
      },
      builder: (context, isFocused, isHovered) {
        final isActive = isFocused || isHovered;
        final baseLayout = style.getBaseLayout(isWideMode: isWideMode);
        final child = UniversalCardRenderer(
          styleName: style.name,
          width: baseLayout.width,
          height: baseLayout.height,
          isActive: isActive,
          isWideMode: isWideMode,
          title: title,
          imageUrl: imageUrl,
          heroTag: tag,
          badgeText: format,
          topRightBadge: badge,
        );

        final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
        final scaleFactor = layout.width / baseLayout.width;
        final normalizedChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(currentTextScale / scaleFactor),
          ),
          child: child,
        );

        return SizedBox(
          width: layout.width,
          height: layout.height,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: baseLayout.width,
              height: baseLayout.height,
              child: normalizedChild,
            ),
          ),
        );
      },
    );
  }
}
