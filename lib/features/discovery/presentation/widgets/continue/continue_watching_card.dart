import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_mixin.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/continue_watching_resolver.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
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
  bool _isFocused = false;
  bool _isHovered = false;

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) {
        _resumeEpisode();
        return null;
      },
    ),
  };

  Future<void> _resumeEpisode() async {
    await handleResumeMedia(
      resolveAndPlay: () async {
        final result = await ref
            .read(continueWatchingResolverProvider)
            .resolve(widget.entry);
        if (!mounted) return;
        context.push(
          '/details/${result.mode.media.type.id}',
          extra: {
            'media': result.mode.media,
            'initialTabIndex': 1,
            'autoPlayMode': result.mode,
          },
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
        context.push(
          '/details/anime',
          extra: UnifiedMedia(
            id: widget.entry.animeId,
            title: MediaTitle(english: widget.entry.animeTitle),
            type: MediaType.ANIME,
            cover: widget.entry.cover ?? widget.entry.thumbnailUrl,
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
    final isActive = _isFocused || _isHovered;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      actions: _actions,
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _resumeEpisode();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onSecondaryTapDown: (details) {
          _showContextMenu(details.globalPosition);
        },
        onLongPressStart: (details) {
          _showContextMenu(details.globalPosition);
        },
        child: _buildStyledContent(widget.style, theme, isActive),
      ),
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

    final baseLayout = style.baseLayout;
    final layout = style.layout;

    final card = ContinueCardLayout(
      isWideBanner: style == ContinueWatchingStyle.wideBanner,
      width: baseLayout.width,
      height: baseLayout.height,
      isActive: isActive,
      isLoading: isLoading,
      title: widget.entry.animeTitle,
      subtitle: style == ContinueWatchingStyle.wideBanner
          ? (widget.entry.episodeTitle ?? 'Continue watching')
          : subtitleText,
      progress: widget.progress,
      progressText: _formatTimeRemaining(),
      badgeText: 'EP ${widget.entry.episodeNumber.toInt()}',
      thumbnailBuilder: (context, cs) =>
          _buildThumbnail(widget.entry.thumbnailUrl, cs),
      fallbackIcon: Icons.play_circle_outline_rounded,
      badgeType: 'WATCHING',
    );

    final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
    final scaleFactor = layout.width / baseLayout.width;
    final normalizedCard = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(currentTextScale / scaleFactor),
      ),
      child: card,
    );

    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: baseLayout.width,
          height: baseLayout.height,
          child: normalizedCard,
        ),
      ),
    );
  }

  String _formatTimeRemaining() {
    final remainingMs =
        widget.entry.durationInMilliseconds -
        widget.entry.positionInMilliseconds;
    if (remainingMs <= 0) return 'Watched';

    final remainingMins = (remainingMs / 60000).ceil();
    return '$remainingMins min left';
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
