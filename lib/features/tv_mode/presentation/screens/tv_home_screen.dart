import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_media_card.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class TvBackdropNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setBackdrop(String? url) {
    if (state != url) {
      state = url;
    }
  }

  void clear() => state = null;
}

final tvFocusedBackdropProvider = NotifierProvider<TvBackdropNotifier, String?>(
  TvBackdropNotifier.new,
);

class TvHomeScreen extends ConsumerWidget {
  const TvHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSections = ref.watch(homeFeedSectionsProvider);
    final backdropUrl = ref.watch(tvFocusedBackdropProvider);

    return AppScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (backdropUrl != null && backdropUrl.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x50FFFFFF),
                        Color(0x20FFFFFF),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.50, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: CachedNetworkImage(
                      key: ValueKey(backdropUrl),
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

          ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            itemCount: activeSections.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 8);
            },
            itemBuilder: (context, index) {
              final section = activeSections[index];
              return _buildSectionWidget(context, ref, section);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWidget(
    BuildContext context,
    WidgetRef ref,
    HomeFeedSection section,
  ) {
    final cardStyles = ref.watch(
      uiPrefsProvider.select(
        (s) => (s.cardStyle, s.continueWatchingStyle, s.continueReadingStyle),
      ),
    );
    return _HomeSectionRow(
      section: section,
      cardStyle: cardStyles.$1,
      continueWatchingStyle: cardStyles.$2,
      continueReadingStyle: cardStyles.$3,
    );
  }
}

class _HomeSectionRow extends ConsumerWidget {
  final HomeFeedSection section;
  final MediaCardStyle cardStyle;
  final ContinueWatchingStyle continueWatchingStyle;
  final ContinueReadingStyle continueReadingStyle;

  const _HomeSectionRow({
    required this.section,
    required this.cardStyle,
    required this.continueWatchingStyle,
    required this.continueReadingStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(homeSectionFeedProvider(section));
    return HorizontalSection(
      data: feedAsync,
      title: section.title,
      itemBuilder: (context, item) {
        return TvMediaCard(
          title: item.title.availableTitle,
          cover: item.cover!,
          banner: item.banner,
          score: item.score,
          description: item.description,
          genres: item.genres,
          year: item.year,
          onFocused: () {
            final backdrop = item.banner?.isNotEmpty == true
                ? item.banner
                : item.cover;
            if (backdrop != null && backdrop.isNotEmpty) {
              ref
                  .read(tvFocusedBackdropProvider.notifier)
                  .setBackdrop(backdrop);
            }
          },
          onTap: () => context.pushDetails(
            mediaType: item.type,
            media: item,
            tag: '${section.id}-${item.id}',
          ),
        );
      },
      height: 210,
    );
  }
}
