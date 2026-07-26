import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/responsive.dart';

class ChapterTransition extends StatelessWidget {
  final String mediaTitle;
  final String currentChapterName;
  final String nextChapterName;
  final bool isNext;
  final bool isLoading;
  final VoidCallback onTrigger;

  const ChapterTransition({
    super.key,
    required this.mediaTitle,
    required this.currentChapterName,
    required this.nextChapterName,
    required this.isNext,
    this.isLoading = false,
    required this.onTrigger,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConstrained =
        ResponsiveData.from(context).isDesktop ||
        ResponsiveData.from(context).isTablet;

    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isConstrained ? 600 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isNext
                      ? Icons.check_circle_outline
                      : Icons.arrow_upward_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  mediaTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isNext
                      ? 'Finished: $currentChapterName'
                      : 'Previous: $nextChapterName',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Text(
                  isNext ? 'Up Next' : 'Currently Reading',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isNext ? nextChapterName : currentChapterName,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNext
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 20,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scroll to load',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
