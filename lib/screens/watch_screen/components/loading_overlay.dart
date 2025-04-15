import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/providers/watch_providers.dart';

/// Loading overlay for the watch screen
class LoadingOverlay extends ConsumerWidget {
  final VoidCallback onRetry;

  const LoadingOverlay({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchState = ref.watch(watchProvider);
    
    if (!watchState.sourceLoading && !watchState.episodesLoading) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              watchState.loadingMessage ?? 'Loading...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Iconsax.repeat_circle),
            )
          ],
        ),
      ),
    );
  }
}
