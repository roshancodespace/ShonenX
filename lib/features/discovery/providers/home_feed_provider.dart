import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class HomeFeedSection {
  final String id;
  final String title;
  final HomeSectionType type;
  final MediaType mediaType;
  final SourceInfo? sourceInfo;
  final HomeSection? homeSection;

  const HomeFeedSection({
    required this.id,
    required this.title,
    this.type = HomeSectionType.discovery,
    this.mediaType = MediaType.ANIME,
    this.sourceInfo,
    this.homeSection,
  });

  bool get isDiscovery => type == HomeSectionType.discovery;
  bool get isContinueMedia => type == HomeSectionType.continueMedia;
  bool get isLibraryStatus => type == HomeSectionType.libraryStatus;
}

final singleSourceFeedProvider =
    FutureProvider.family<List<UnifiedMedia>, (SourceInfo, MediaType)>((
      ref,
      arg,
    ) async {
      final (info, mediaType) = arg;
      try {
        final source = mediaType == MediaType.ANIME
            ? ref.read(animeSourceProvider(info))
            : ref.read(mangaSourceProvider(info));

        var items = await source.getTrending();
        if (items.isEmpty) items = await source.search('', mediaType);
        return items;
      } catch (e) {
        try {
          final source = mediaType == MediaType.ANIME
              ? ref.read(animeSourceProvider(info))
              : ref.read(mangaSourceProvider(info));
          return await source.search('', mediaType);
        } catch (_) {
          return const [];
        }
      }
    });

final homeFeedSectionsProvider = Provider<List<HomeFeedSection>>((ref) {
  final mode = ref.watch(discoveryPrefsProvider.select((p) => p.mode));

  if (mode == MetadataMode.source) {
    final prefs = ref.watch(discoveryPrefsProvider);
    final allAnime = ref.watch(availableAnimeSourcesProvider).value ?? [];
    final allManga = ref.watch(availableMangaSourcesProvider).value ?? [];

    final activeAnime = allAnime.where(
      (s) => prefs.activeSources.contains(s.id),
    );
    final activeManga = allManga.where(
      (s) => prefs.activeSources.contains(s.id),
    );

    final sections = <HomeFeedSection>[];

    for (final info in activeAnime) {
      sections.add(
        HomeFeedSection(
          id: 'src-anime-${info.id}',
          title: '${info.name} (Anime)',
          type: HomeSectionType.discovery,
          mediaType: MediaType.ANIME,
          sourceInfo: info,
        ),
      );
    }

    for (final info in activeManga) {
      sections.add(
        HomeFeedSection(
          id: 'src-manga-${info.id}',
          title: '${info.name} (Manga)',
          type: HomeSectionType.discovery,
          mediaType: MediaType.MANGA,
          sourceInfo: info,
        ),
      );
    }

    return sections;
  } else {
    final userSections = ref
        .watch(userHomeLayoutProvider)
        .where((s) => !s.disabled)
        .toList();

    return userSections.map((s) {
      return HomeFeedSection(
        id: s.id,
        title: s.title,
        type: s.type,
        mediaType: s.targetMediaType ?? MediaType.ANIME,
        homeSection: s,
      );
    }).toList();
  }
});

final homeSectionFeedProvider =
    FutureProvider.family<List<UnifiedMedia>, HomeFeedSection>((
      ref,
      section,
    ) async {
      // 1. Source extension mode
      if (section.sourceInfo != null) {
        return ref.watch(
          singleSourceFeedProvider((
            section.sourceInfo!,
            section.mediaType,
          )).future,
        );
      }

      // 2. Tracker mode
      final hs = section.homeSection;
      if (hs == null || hs.type != HomeSectionType.discovery) return const [];

      final tracker = ref.watch(metadataSourceProvider);
      final adultMode = ref.watch(contentPrefsProvider).adultContentMode;
      final category = hs.trackerCategory ?? TrackerCategory.trending;

      final result = await tracker.getCategoryItems(
        category,
        type: section.mediaType,
        adultMode: adultMode,
        cacheDuration: const Duration(hours: 12),
      );
      return result.items;
    });

final homeSpotlightItemsProvider = FutureProvider<List<UnifiedMedia>>((
  ref,
) async {
  final sections = ref.watch(homeFeedSectionsProvider);
  final firstDiscovery = sections.where((s) => s.isDiscovery).firstOrNull;
  if (firstDiscovery == null) return const [];
  return ref.watch(homeSectionFeedProvider(firstDiscovery).future);
});
