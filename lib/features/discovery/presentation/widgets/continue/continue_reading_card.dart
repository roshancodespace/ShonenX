import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_mixin.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/providers/continue_reading_resolver.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'continue_card_layout.dart';

class ContinueReadingItem extends ConsumerStatefulWidget {
  final ReadHistoryEntry entry;
  final double progress;
  final ContinueReadingStyle style;

  const ContinueReadingItem({
    super.key,
    required this.entry,
    required this.progress,
    required this.style,
  });

  @override
  ConsumerState<ContinueReadingItem> createState() =>
      _ContinueReadingItemState();
}

class _ContinueReadingItemState extends ConsumerState<ContinueReadingItem>
    with ContinueMediaMixin {
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
        final result = await ref
            .read(continueReadingResolverProvider)
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
      onViewDetails: () {
        context.push(
          '/details/manga',
          extra: UnifiedMedia(
            id: widget.entry.mangaId,
            title: MediaTitle(english: widget.entry.mangaTitle),
            type: MediaType.MANGA,
            cover: widget.entry.cover,
            banner: widget.entry.banner,
          ),
        );
      },
      onRemoveHistory: () =>
          ref.read(readHistoryRepositoryProvider).deleteEntry(widget.entry.id),
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
        onSecondaryTapDown: (details) =>
            _showContextMenu(details.globalPosition),
        onLongPressStart: (details) => _showContextMenu(details.globalPosition),
        child: _buildStyledContent(widget.style, theme, isActive),
      ),
    );
  }

  Widget _buildStyledContent(
    ContinueReadingStyle style,
    ThemeData theme,
    bool isActive,
  ) {
    final epNum = widget.entry.chapterNumber;
    final cleanNum = epNum.toString().contains('.0') ? epNum.toInt() : epNum;
    final epTitle = widget.entry.chapterTitle;
    final subtitleText = 'CH $cleanNum${epTitle != null ? ' • $epTitle' : ''}';

    final baseLayout = style.baseLayout;
    final layout = style.layout;

    final card = ContinueCardLayout(
      isWideBanner: style == ContinueReadingStyle.wideBanner,
      width: baseLayout.width,
      height: baseLayout.height,
      isActive: isActive,
      isLoading: isLoading,
      title: widget.entry.mangaTitle,
      subtitle: style == ContinueReadingStyle.wideBanner
          ? (widget.entry.chapterTitle ?? 'Continue reading')
          : subtitleText,
      progress: widget.progress,
      progressText: '${(widget.progress * 100).toInt()}% read',
      badgeText: 'CH ${widget.entry.chapterNumber.toInt()}',
      imageUrl: widget.entry.banner ?? widget.entry.cover,
      fallbackIcon: Icons.menu_book_rounded,
      badgeType: 'READING',
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
}
