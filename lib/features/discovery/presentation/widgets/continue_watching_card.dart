import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/features/discovery/presentation/widgets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/continue_watching_resolver.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

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

class _ContinueWatchingItemState extends ConsumerState<ContinueWatchingItem> {
  static const _contentPadding = 5.0;

  bool _isLoading = false;
  bool _isFocused = false;
  bool _isHovered = false;

  Future<void> _resumeEpisode() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref
          .read(continueWatchingResolverProvider)
          .resolve(widget.entry);

      if (!mounted) return;

      setState(() => _isLoading = false);

      context.push('/player', extra: result.params);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showSourceError(e);
    }
  }

  Future<void> _showSourceError(Object error) async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) {
        return AppBottomSheet(
          title: 'Source Error',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        Navigator.pop(context);

                        await ref
                            .read(
                              sourcePreferenceProvider(
                                widget.entry.animeTitle,
                              ).notifier,
                            )
                            .clearPreference();

                        if (mounted) {
                          _resumeEpisode();
                        }
                      },
                      child: const Text('Auto Match'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          builder: (_) {
                            return ManualMatchSheet(
                              mediaTitle: widget.entry.animeTitle,
                              type: MediaType.ANIME,
                            );
                          },
                        );

                        if (result == true && mounted) {
                          _resumeEpisode();
                        }
                      },
                      child: const Text('Manual Match'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showItemContextMenu(Offset position) async {
    final entry = widget.entry;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: 'clear', child: Text('Clear Source Preference')),
        PopupMenuItem(
          value: 'remove_history',
          child: Text('Remove from History'),
        ),
        PopupMenuItem(value: 'fix_match', child: Text('Fix Match')),
      ],
    );

    if (value == 'clear' && mounted) {
      await ref
          .read(sourcePreferenceProvider(entry.animeTitle).notifier)
          .clearPreference();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source preference cleared')),
      );
    }

    if (value == 'remove_history' && mounted) {
      await ref.read(watchHistoryRepositoryProvider).deleteEntry(entry.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from history')));
    }

    if (value == 'fix_match' && mounted) {
      await showModalBottomSheet(
        context: context,
        builder: (_) {
          return ManualMatchSheet(
            mediaTitle: entry.animeTitle,
            type: MediaType.ANIME,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _isFocused || _isHovered;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _resumeEpisode();
            return null;
          },
        ),
      },
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _resumeEpisode();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onSecondaryTapDown: (details) {
          _showItemContextMenu(details.globalPosition);
        },
        onLongPressStart: (details) {
          _showItemContextMenu(details.globalPosition);
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
    switch (style) {
      case ContinueWatchingStyle.wideBanner:
        return _buildWideBanner(theme, isActive);

      case ContinueWatchingStyle.classic:
        return _buildClassic(theme, isActive);
    }
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
            progressInset: 0,
            isActive: isActive,
            layers: [
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'CONTINUE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.entry.animeTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatEpisodeText(),
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
          color: isActive
              ? cs.tertiary
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isActive ? 2.5 : 0.0,
        ),
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_contentPadding),
        child: Row(
          children: [
            Expanded(
              child: _buildThumbnailStack(
                aspectRatio: 16 / 10,
                borderRadius: 20,
                progressInset: 0,
                isActive: false,
                layers: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'EP ${widget.entry.episodeNumber.toInt()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.entry.animeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.entry.episodeTitle ?? 'Continue watching',
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
                    child: SizedBox(
                      width: double.infinity,
                      child: LinearProgressIndicator(
                        value: widget.progress.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(widget.progress * 100).toInt()}% watched',
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
      ),
    );
  }

  String _formatEpisodeText() {
    final epNum = widget.entry.episodeNumber;

    final cleanNum = epNum.toString().contains('.0') ? epNum.toInt() : epNum;

    final epTitle = widget.entry.episodeTitle;

    return 'EP $cleanNum${epTitle != null ? ' • $epTitle' : ''}';
  }

  Widget _buildThumbnailStack({
    required double aspectRatio,
    required double borderRadius,
    required double progressInset,
    required bool isActive,
    List<Widget>? layers,
  }) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final thumbnail = widget.entry.thumbnailUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnail(thumbnail, cs),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1],
                    colors: [
                      Colors.transparent,
                      cs.scrim.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: progressInset,
              right: progressInset,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: widget.progress.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: Colors.black26,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
              ),
            ),

            if (layers != null) ...layers,

            Positioned.fill(
              child: AnimatedContainer(
                duration: Durations.short4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isActive ? cs.tertiary : Colors.transparent,
                    width: isActive ? 2.5 : 0.0,
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
          ],
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
          errorWidget: (_, __, ___) => Container(
            color: cs.surfaceContainerHighest,
            child: Icon(Icons.broken_image_rounded, color: cs.onSurfaceVariant),
          ),
        );
      }

      return Image.memory(
        base64Decode(thumbnail),
        fit: BoxFit.cover,
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
