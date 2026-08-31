import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_mixin.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/continue_reading_resolver.dart';
import 'package:shonenx/features/history/providers/continue_watching_resolver.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/screens/tv_home_screen.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_continue_card.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class TvContinueMediaRow extends ConsumerStatefulWidget {
  final String title;
  final MediaType type;
  final int limit;
  final double height;

  const TvContinueMediaRow({
    super.key,
    required this.title,
    required this.type,
    this.limit = 10,
    this.height = 210.0,
  });

  @override
  ConsumerState<TvContinueMediaRow> createState() => _TvContinueMediaRowState();
}

class _TvContinueMediaRowState extends ConsumerState<TvContinueMediaRow>
    with ContinueMediaMixin {
  Future<void> _resumeWatchEntry(WatchHistoryEntry entry) async {
    await handleResumeMedia(
      resolveAndPlay: () async {
        final mode = await ref
            .read(continueWatchingResolverProvider)
            .resolve(entry);
        if (!mounted) return;
        context.pushDetails(
          mediaType: mode.media.type,
          media: mode.media,
          initialTabIndex: 1,
          autoPlayMode: mode,
        );
      },
      mediaType: MediaType.ANIME,
      mediaTitle: entry.animeTitle,
      availableSourcesProvider: availableAnimeSourcesProvider,
    );
  }

  Future<void> _resumeReadEntry(ReadHistoryEntry entry) async {
    await handleResumeMedia(
      resolveAndPlay: () async {
        final mode = await ref
            .read(continueReadingResolverProvider)
            .resolve(entry);
        if (!mounted) return;
        context.pushDetails(
          mediaType: mode.media.type,
          media: mode.media,
          initialTabIndex: 1,
          autoPlayMode: mode,
        );
      },
      mediaType: MediaType.MANGA,
      mediaTitle: entry.mangaTitle,
      availableSourcesProvider: availableMangaSourcesProvider,
    );
  }

  void _syncBackdrop(String? banner, String? cover) {
    final backdrop = (banner != null && banner.isNotEmpty) ? banner : cover;
    if (backdrop != null && backdrop.isNotEmpty) {
      ref.read(tvFocusedBackdropProvider.notifier).setBackdrop(backdrop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnime = widget.type == MediaType.ANIME;

    final asyncData = isAnime
        ? ref.watch(continueWatchingPerAnimeProvider(widget.limit))
        : ref.watch(continueReadingPerMangaProvider(widget.limit));

    if (asyncData.value?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    return HorizontalSection(
      title: widget.title,
      height: widget.height,
      emptyText: isAnime ? 'No anime in this list.' : 'No manga in this list.',
      data: asyncData,
      onMoreTap: () => context.pushContinueHistory(widget.type),
      itemBuilder: (context, dynamic entry) {
        if (isAnime) {
          final watchEntry = entry as WatchHistoryEntry;
          return TvContinueCard.fromWatchEntry(
            entry: watchEntry,
            onFocused: () => _syncBackdrop(watchEntry.banner, watchEntry.cover),
            onTap: () => _resumeWatchEntry(watchEntry),
            onLongPress: () {
              context.pushDetails(
                mediaType: MediaType.ANIME,
                media: UnifiedMedia(
                  id: watchEntry.animeId,
                  title: MediaTitle(english: watchEntry.animeTitle),
                  type: MediaType.ANIME,
                  cover: watchEntry.cover,
                  banner: watchEntry.banner,
                ),
              );
            },
          );
        } else {
          final readEntry = entry as ReadHistoryEntry;
          return TvContinueCard.fromReadEntry(
            entry: readEntry,
            onFocused: () => _syncBackdrop(readEntry.banner, readEntry.cover),
            onTap: () => _resumeReadEntry(readEntry),
            onLongPress: () {
              context.pushDetails(
                mediaType: MediaType.MANGA,
                media: UnifiedMedia(
                  id: readEntry.mangaId,
                  title: MediaTitle(english: readEntry.mangaTitle),
                  type: MediaType.MANGA,
                  cover: readEntry.cover,
                  banner: readEntry.banner,
                ),
              );
            },
          );
        }
      },
    );
  }
}
