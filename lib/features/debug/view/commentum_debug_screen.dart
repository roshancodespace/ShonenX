import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/details/view/widgets/comments_bottom_sheet.dart';

class CommentumDebugScreen extends StatelessWidget {
  const CommentumDebugScreen({super.key});

  static const _debugAnime = UniversalMedia(
    id: '172463',
    title: UniversalTitle(english: 'Debug Anime', romaji: 'Debug Anime'),
    coverImage: UniversalCoverImage(
      large:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx172463-7183.jpg',
    ),
    seasonYear: 2024,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Commentum Debug'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Commentum Debug',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test the comment system with a debug anime entry',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => CommentsBottomSheet.show(context, _debugAnime),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Comments Sheet'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
