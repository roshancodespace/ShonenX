import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/recommendations/providers/recommendations_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class LikeButton extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBackground;

  const LikeButton({
    super.key,
    required this.media,
    this.size = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.showBackground = false,
  });

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.mediumImpact();
    _animController.forward(from: 0.0);

    final isNowLiked = await ref
        .read(likedAnimeProvider.notifier)
        .toggleLike(widget.media);

    if (mounted) {
      final title = widget.media.title.availableTitle;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isNowLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isNowLiked ? Colors.redAccent : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isNowLiked
                      ? 'Added "$title" to Likes • Recommendations updated'
                      : 'Removed "$title" from Likes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(
      likedAnimeProvider.select((map) => map.containsKey(widget.media.id)),
    );
    final theme = Theme.of(context);
    final activeCol = widget.activeColor ?? Colors.redAccent;
    final inactiveCol =
        widget.inactiveColor ?? theme.colorScheme.onSurfaceVariant;

    Widget iconWidget = ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: widget.size,
        color: isLiked ? activeCol : inactiveCol,
      ),
    );

    if (widget.showBackground) {
      return Material(
        color: isLiked
            ? activeCol.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: iconWidget,
          ),
        ),
      );
    }

    return IconButton(
      icon: iconWidget,
      tooltip: isLiked ? 'Unlike Anime' : 'Like Anime',
      onPressed: _handleTap,
    );
  }
}
