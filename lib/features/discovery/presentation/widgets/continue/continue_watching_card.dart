import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_mixin.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/continue_watching_resolver.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'continue_card_layout.dart';

class ContinueWatchingItem extends ConsumerStatefulWidget {
  final WatchHistoryEntry entry;
  final double progress;
  final ContinueWatchingStyle style;

  const ContinueWatchingItem({
    super.key,
    required this.entry,
    required this.progress,
    required this.style,
  });

  @override
  ConsumerState<ContinueWatchingItem> createState() =>
      _ContinueWatchingItemState();
}

class _ContinueWatchingItemState extends ConsumerState<ContinueWatchingItem>
    with ContinueMediaMixin {
  Future<void> _resumeEpisode() async {
    await handleResumeMedia(
      resolveAndPlay: () async {
        final mode = await ref
            .read(continueWatchingResolverProvider)
            .resolve(widget.entry);
        if (!mounted) return;
        context.pushDetails(
          mediaType: mode.media.type,
          media: mode.media,
          initialTabIndex: 1,
          autoPlayMode: mode,
        );
      },
      mediaType: MediaType.ANIME,
      mediaTitle: widget.entry.animeTitle,
      availableSourcesProvider: availableAnimeSourcesProvider,
    );
  }

  void _showContextMenu(Offset position) {
    showItemContextMenu(
      position: position,
      mediaType: MediaType.ANIME,
      mediaTitle: widget.entry.animeTitle,
      onViewDetails: () {
        context.pushDetails(
          mediaType: MediaType.ANIME,
          media: UnifiedMedia(
            id: widget.entry.animeId,
            title: MediaTitle(english: widget.entry.animeTitle),
            type: MediaType.ANIME,
            cover: widget.entry.cover,
            banner: widget.entry.banner,
          ),
        );
      },
      onRemoveHistory: () =>
          ref.read(watchHistoryRepositoryProvider).deleteEntry(widget.entry.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppFocusHover(
      onTap: () {
        _resumeEpisode();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onSecondaryTapDown: (details) => _showContextMenu(details.globalPosition),
      onLongPressStart: (details) => _showContextMenu(details.globalPosition),
      builder: (context, isFocused, isHovered) {
        return _buildStyledContent(widget.style, theme, isFocused || isHovered);
      },
    );
  }

  Widget _buildStyledContent(
    ContinueWatchingStyle style,
    ThemeData theme,
    bool isActive,
  ) {
    final epNum = widget.entry.episodeNumber;
    final cleanNum = epNum.toString().contains('.0') ? epNum.toInt() : epNum;
    final epTitle = widget.entry.episodeTitle;
    final subtitleText = 'EP $cleanNum${epTitle != null ? ' • $epTitle' : ''}';

    final isWideMode = ref.watch(
      uiPrefsProvider.select((s) => s.isContinueWatchingWide(style.name)),
    );
    final baseLayout = style.getBaseLayout(
      isContinueWatching: true,
      isWideMode: isWideMode,
    );
    final layout = style.getLayout(
      isContinueWatching: true,
      isWideMode: isWideMode,
    );

    final card = ContinueCardLayout(
      variant: style.name,
      width: baseLayout.width,
      height: baseLayout.height,
      isActive: isActive,
      isLoading: isLoading,
      isWideMode: isWideMode,
      title: widget.entry.animeTitle,
      subtitle: style == ContinueWatchingStyle.wideBanner
          ? (widget.entry.episodeTitle ?? 'Continue watching')
          : subtitleText,
      progress: widget.progress,
      progressText: formatTimeRemaining(
        widget.entry.durationInMilliseconds -
            widget.entry.positionInMilliseconds,
      ),
      badgeText: 'EP ${widget.entry.episodeNumber.toInt()}',
      thumbnailBuilder: (context, cs) =>
          _buildThumbnail(widget.entry.thumbnailUrl, cs),
      fallbackIcon: Icons.play_circle_outline_rounded,
      badgeType: 'WATCHING',
    );

    final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
    final scaleFactor = layout.width / baseLayout.width;
    final normalizedCard = MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(currentTextScale / scaleFactor)),
      child: card,
    );

    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: RepaintBoundary(
        child: AnimatedScale(
          scale: isActive ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: baseLayout.width,
              height: baseLayout.height,
              child: normalizedCard,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? thumbnail, ColorScheme cs) {
    if (thumbnail == null || thumbnail.isEmpty) {
      return Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.movie_creation_outlined, color: cs.onSurfaceVariant),
      );
    }

    try {
      if (thumbnail.startsWith('http')) {
        final imageUrl = thumbnail.split('#').first;
        final headers = decodeUrlHeaders(thumbnail);

        return CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: headers.isEmpty ? null : headers,
          fit: BoxFit.cover,
          memCacheWidth: 600,
          maxWidthDiskCache: 800,
          errorWidget: (_, __, ___) => Container(
            color: cs.surfaceContainerHighest,
            child: Icon(Icons.broken_image_rounded, color: cs.onSurfaceVariant),
          ),
        );
      }

      return Image.memory(
        base64Decode(thumbnail),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.broken_image_rounded, color: cs.onSurfaceVariant),
        ),
      );
    } catch (_) {
      return Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.broken_image_rounded, color: cs.onSurfaceVariant),
      );
    }
  }
}
