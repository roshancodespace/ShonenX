import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_mixin.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/features/history/providers/continue_history_resolver.dart';
import 'package:shonenx/features/history/providers/history_provider.dart';
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
  Future<void> _resumeEntry(HistoryEntry entry) async {
    final isAnime = entry.mediaType == MediaType.ANIME.id;
    await handleResumeMedia(
      resolveAndPlay: () async {
        final mode = await ref
            .read(continueHistoryResolverProvider)
            .resolve(entry);
        if (!mounted) return;
        context.pushDetails(
          mediaType: mode.media.type,
          media: mode.media,
          initialTabIndex: 1,
          autoPlayMode: mode,
        );
      },
      mediaType: isAnime ? MediaType.ANIME : MediaType.MANGA,
      mediaTitle: entry.mediaTitle,
      availableSourcesProvider: isAnime
          ? availableAnimeSourcesProvider
          : availableMangaSourcesProvider,
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

    final asyncData = ref.watch(
      historyPerMediaProvider((mediaType: widget.type.id, limit: widget.limit)),
    );

    if (asyncData.value?.isEmpty == true) {
      return const SizedBox.shrink();
    }

    return HorizontalSection(
      title: widget.title,
      height: widget.height,
      emptyText: isAnime ? 'No anime in this list.' : 'No manga in this list.',
      data: asyncData,
      onMoreTap: () => context.pushContinueHistory(widget.type),
      itemBuilder: (context, dynamic dynamicEntry) {
        final entry = dynamicEntry as HistoryEntry;
        return TvContinueCard.fromHistoryEntry(
          entry: entry,
          onFocused: () => _syncBackdrop(entry.banner, entry.cover),
          onTap: () => _resumeEntry(entry),
          onLongPress: () {
            context.pushDetails(
              mediaType: widget.type,
              media: UnifiedMedia(
                id: entry.mediaId,
                title: MediaTitle(english: entry.mediaTitle),
                type: widget.type,
                cover: entry.cover,
                banner: entry.banner,
              ),
            );
          },
        );
      },
    );
  }
}
