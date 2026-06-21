import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue_media_mixin.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/providers/continue_reading_resolver.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class ContinueReadingItem extends ConsumerStatefulWidget {
  final ReadHistoryEntry entry;
  final double progress;
  final ContinueWatchingStyle style;

  const ContinueReadingItem({
    super.key,
    required this.entry,
    required this.progress,
    required this.style,
  });

  @override
  ConsumerState<ContinueReadingItem> createState() => _ContinueReadingItemState();
}

class _ContinueReadingItemState extends ConsumerState<ContinueReadingItem> with ContinueMediaMixin {
  bool _isFocused = false;
  bool _isHovered = false;

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) {
        _resumeReading();
        return null;
      },
    ),
  };

  Future<void> _resumeReading() async {
    await handleResumeMedia(
      resolveAndPlay: () async {
        final result = await ref.read(continueReadingResolverProvider).resolve(widget.entry);
        if (mounted) context.push('/reader', extra: result.mode);
      },
      mediaType: MediaType.MANGA,
      mediaTitle: widget.entry.mangaTitle,
      availableSourcesProvider: availableMangaSourcesProvider,
    );
  }

  void _showContextMenu(Offset position) {
    showItemContextMenu(
      position: position,
      mediaType: MediaType.MANGA,
      mediaTitle: widget.entry.mangaTitle,
      onRemoveHistory: () => ref.read(readHistoryRepositoryProvider).deleteEntry(widget.entry.id),
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
          _resumeReading();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onSecondaryTapDown: (details) => _showContextMenu(details.globalPosition),
        onLongPressStart: (details) => _showContextMenu(details.globalPosition),
        child: widget.style == ContinueWatchingStyle.wideBanner
            ? _buildWideBanner(theme, isActive)
            : _buildClassic(theme, isActive),
      ),
    );
  }

  Widget _buildClassic(ThemeData theme, bool isActive) {
    final cs = theme.colorScheme;

    return SizedBox(
      width: widget.style.layout.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnailStack(
            aspectRatio: 16 / 9,
            borderRadius: 20,
            isActive: isActive,
            badge: _buildBadge(
              theme,
              text: 'READING',
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.92),
              textColor: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.entry.mangaTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatChapterText(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideBanner(ThemeData theme, bool isActive) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: Durations.short4,
      width: widget.style.layout.width,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? cs.tertiary : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 0.0,
        ),
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(5.0),
      child: Row(
        children: [
          Expanded(
            child: _buildThumbnailStack(
              aspectRatio: 16 / 10,
              borderRadius: 20,
              isActive: false,
              badge: _buildBadge(
                theme,
                text: 'CH ${widget.entry.chapterNumber.toInt()}',
                backgroundColor: cs.primaryContainer,
                textColor: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.entry.mangaTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.entry.chapterTitle ?? 'Continue reading',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: widget.progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(widget.progress * 100).toInt()}% read',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatChapterText() {
    final epNum = widget.entry.chapterNumber;
    final cleanNum = epNum.toString().contains('.0') ? epNum.toInt() : epNum;
    final epTitle = widget.entry.chapterTitle;

    return 'CH $cleanNum${epTitle != null ? ' • $epTitle' : ''}';
  }

  Widget _buildBadge(
    ThemeData theme, {
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailStack({
    required double aspectRatio,
    required double borderRadius,
    required bool isActive,
    Widget? badge,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final thumbnail = widget.entry.banner ?? widget.entry.cover;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnail != null && thumbnail.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumbnail,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildFallbackImage(cs),
              )
            else
              _buildFallbackImage(cs),

            // Gradient Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.45, 1],
                  colors: [Colors.transparent, cs.scrim.withValues(alpha: 0.75)],
                ),
              ),
            ),

            // Progress Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: widget.progress.clamp(0, 1),
                minHeight: 4,
                backgroundColor: Colors.black26,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),

            if (badge != null) badge,

            // Active Border Overlay
            AnimatedContainer(
              duration: Durations.short4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isActive ? cs.tertiary : Colors.transparent,
                  width: isActive ? 2.5 : 0.0,
                ),
              ),
            ),

            // Loading Overlay
            if (isLoading)
              const ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(ColorScheme cs) {
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.menu_book_rounded, color: cs.onSurfaceVariant),
    );
  }
}
