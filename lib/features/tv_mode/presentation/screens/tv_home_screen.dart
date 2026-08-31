import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_backdrop_background.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_continue_media_row.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_library_row.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_media_card.dart';
import 'package:shonenx/shared/models/unified_media.dart';
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

    return AppScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const TvBackdropBackground(),

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
    switch (section.type) {
      case HomeSectionType.continueMedia:
        return TvContinueMediaRow(
          title: section.title,
          type: section.mediaType,
        );

      case HomeSectionType.libraryStatus:
        final hs = section.homeSection;
        if (hs == null || hs.libraryStatus == null) {
          return const SizedBox.shrink();
        }
        final activeTracker = hs.targetTracker != null
            ? ref
                  .watch(availableTrackersProvider)
                  .firstWhere((t) => t.type == hs.targetTracker!)
            : ref.watch(primaryTrackerProvider);

        return TvLibraryRow(
          title: section.title,
          status: hs.libraryStatus!,
          targetTracker: activeTracker.type,
          targetMediaType: section.mediaType,
        );

      case HomeSectionType.discovery:
        final cardStyles = ref.watch(
          uiPrefsProvider.select(
            (s) =>
                (s.cardStyle, s.continueWatchingStyle, s.continueReadingStyle),
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
    return HorizontalSection<UnifiedMedia>(
      data: feedAsync,
      title: section.title,
      itemBuilder: (context, item) {
        return TvMediaCard(
          title: item.title.availableTitle,
          cover: item.cover ?? '',
          banner: item.banner,
          score: item.score,
          totalEpisodes: item.episodes,
          format: item.format,
          status: item.status,
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
