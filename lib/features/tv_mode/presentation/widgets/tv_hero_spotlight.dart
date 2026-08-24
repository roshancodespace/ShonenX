import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class TvHeroSpotlight extends StatefulWidget {
  final UnifiedMedia? media;
  final List<UnifiedMedia>? items;
  final VoidCallback? onPlay;
  final ValueChanged<UnifiedMedia>? onPlayMedia;
  final VoidCallback? onDetails;
  final ValueChanged<UnifiedMedia>? onDetailsMedia;
  final VoidCallback? onBookmark;
  final ValueChanged<UnifiedMedia>? onBookmarkMedia;
  final bool isBookmarked;
  final bool autoPlay;
  final Duration autoPlayDuration;

  const TvHeroSpotlight({
    super.key,
    this.media,
    this.items,
    this.onPlay,
    this.onPlayMedia,
    this.onDetails,
    this.onDetailsMedia,
    this.onBookmark,
    this.onBookmarkMedia,
    this.isBookmarked = false,
    this.autoPlay = true,
    this.autoPlayDuration = const Duration(seconds: 6),
  });

  @override
  State<TvHeroSpotlight> createState() => _TvHeroSpotlightState();
}

class _TvHeroSpotlightState extends State<TvHeroSpotlight> {
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  List<UnifiedMedia> get _mediaList {
    if (widget.items != null && widget.items!.isNotEmpty) {
      return widget.items!;
    }
    if (widget.media != null) {
      return [widget.media!];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _restartAutoScrollTimer();
  }

  @override
  void didUpdateWidget(covariant TvHeroSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mediaList.isNotEmpty && _currentIndex >= _mediaList.length) {
      setState(() => _currentIndex = 0);
    }
    if (widget.autoPlay != oldWidget.autoPlay ||
        widget.autoPlayDuration != oldWidget.autoPlayDuration ||
        widget.items != oldWidget.items) {
      _restartAutoScrollTimer();
    }
  }

  void _restartAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    if (!widget.autoPlay || _mediaList.length <= 1) return;

    _autoScrollTimer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!mounted) return;
      _nextSlide(resetTimer: false);
    });
  }

  void _nextSlide({bool resetTimer = true}) {
    if (_mediaList.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _mediaList.length;
    });
    if (resetTimer) _restartAutoScrollTimer();
  }

  void _prevSlide({bool resetTimer = true}) {
    if (_mediaList.isEmpty) return;
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + _mediaList.length) % _mediaList.length;
    });
    if (resetTimer) _restartAutoScrollTimer();
  }

  void _handlePlay(UnifiedMedia media) {
    if (widget.onPlayMedia != null) {
      widget.onPlayMedia!(media);
    } else if (widget.onPlay != null) {
      widget.onPlay!();
    }
  }

  void _handleDetails(UnifiedMedia media) {
    if (widget.onDetailsMedia != null) {
      widget.onDetailsMedia!(media);
    } else if (widget.onDetails != null) {
      widget.onDetails!();
    }
  }

  void _handleBookmark(UnifiedMedia media) {
    if (widget.onBookmarkMedia != null) {
      widget.onBookmarkMedia!(media);
    } else if (widget.onBookmark != null) {
      widget.onBookmark!();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final mediaList = _mediaList;

    if (mediaList.isEmpty) {
      return const SizedBox(height: 400);
    }

    final m = mediaList[_currentIndex.clamp(0, mediaList.length - 1)];
    final title = m.title.availableTitle;
    final backdrop = m.banner ?? m.cover ?? '';
    final score = m.score;
    final format = m.format;
    final year = m.season;
    final status = m.status;
    final description = m.description ?? '';
    final genres = m.genres ?? [];
    final scale = context.tvScale;

    final heroHeight = (size.height * 0.54).clamp(380.0, 700.0);
    final leftPadding = (44.0 * scale).clamp(36.0, 84.0);
    final bottomPadding = (36.0 * scale).clamp(28.0, 68.0);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: backdrop.isNotEmpty
                    ? TvSmartImage(
                        key: ValueKey('spotlight_bg_${m.id}'),
                        imageUrl: backdrop,
                        fit: BoxFit.cover,
                        memCacheWidth: 1600,
                        maxWidthDiskCache: 1800,
                        fadeFromBottom: true,
                        fadeFromLeft: true,
                        fadeStops: const [0.0, 0.15, 0.45, 0.70, 0.85, 1.0],
                      )
                    : Container(
                        key: ValueKey('spotlight_empty_${m.id}'),
                        color: cs.surface,
                      ),
              ),
            ),

            Positioned(
              left: leftPadding,
              bottom: bottomPadding,
              right: size.width * 0.30,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey('spotlight_info_${m.id}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (score != null && score > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB703),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  score.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (format != null && format.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              format.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                        if (year != null && year.isNotEmpty) ...[
                          Text(
                            year,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (status != null && status.isNotEmpty) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: status.toLowerCase() == 'releasing'
                                      ? Colors.greenAccent
                                      : Colors.white54,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: status.toLowerCase() == 'releasing'
                                      ? Colors.greenAccent
                                      : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.15,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: genres.take(4).map((g) {
                          return Text(
                            g,
                            style: TextStyle(
                              color: cs.primary.withValues(alpha: 0.95),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (description.isNotEmpty) ...[
                      Text(
                        description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      children: [
                        _SpatialActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Watch Now',
                          isPrimary: true,
                          onPressed: () => _handlePlay(m),
                        ),
                        const SizedBox(width: 12),
                        _SpatialActionButton(
                          icon: Icons.info_outline_rounded,
                          label: 'Details',
                          isPrimary: false,
                          onPressed: () => _handleDetails(m),
                        ),
                        if (widget.onBookmark != null ||
                            widget.onBookmarkMedia != null) ...[
                          const SizedBox(width: 12),
                          _SpatialActionButton(
                            icon: widget.isBookmarked
                                ? Icons.bookmark_added_rounded
                                : Icons.bookmark_add_outlined,
                            label: widget.isBookmarked
                                ? 'In List'
                                : 'Add to List',
                            isPrimary: false,
                            onPressed: () => _handleBookmark(m),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (mediaList.length > 1)
              Positioned(
                right: (44.0 * scale).clamp(32.0, 72.0),
                bottom: (36.0 * scale).clamp(28.0, 60.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SpotlightNavButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: _prevSlide,
                    ),
                    const SizedBox(width: 10),
                    ...List.generate(mediaList.length, (index) {
                      final isActive = index == _currentIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22.0 : 6.0,
                        height: 5.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isActive
                              ? cs.primary
                              : Colors.white.withValues(alpha: 0.25),
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                    _SpotlightNavButton(
                      icon: Icons.chevron_right_rounded,
                      onPressed: _nextSlide,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SpotlightNavButton({required this.icon, required this.onPressed});

  @override
  State<_SpotlightNavButton> createState() => _SpotlightNavButtonState();
}

class _SpotlightNavButtonState extends State<_SpotlightNavButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: InkWell(
          canRequestFocus: false,
          onTap: () {
            _focusNode.requestFocus();
            widget.onPressed();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isFocused
                  ? cs.primary
                  : Colors.black.withValues(alpha: 0.45),
              border: Border.all(
                color: _isFocused
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
                width: _isFocused ? 2.0 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: _isFocused ? cs.onPrimary : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpatialActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _SpatialActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_SpatialActionButton> createState() => _SpatialActionButtonState();
}

class _SpatialActionButtonState extends State<_SpatialActionButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = widget.isPrimary
        ? (_isFocused ? cs.primary.withValues(alpha: 0.9) : cs.primary)
        : (_isFocused
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12));

    final fgColor = Colors.white;

    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: InkWell(
          canRequestFocus: false,
          onTap: () {
            _focusNode.requestFocus();
            widget.onPressed();
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: widget.isPrimary
                            ? cs.primary.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 20, color: fgColor),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
