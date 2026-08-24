import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/library/providers/library_view_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class TvLibraryScreen extends ConsumerWidget {
  const TvLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(libraryViewStateProvider);
    final viewNotifier = ref.read(libraryViewStateProvider.notifier);
    final libraryEntriesAsync = ref.watch(dynamicLibraryProvider);
    final cardStyle = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((p) => p.isMediaCardWide(cardStyle.name)),
    );
    final size = MediaQuery.sizeOf(context);
    final scale = context.tvScale;

    final crossAxisCount = (size.width / (isWide ? 260 * scale : 190 * scale))
        .floor()
        .clamp(3, 8);

    final horizontalPad = (36.0 * scale).clamp(28.0, 64.0);
    final topPad = (16.0 * scale).clamp(12.0, 28.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, topPad, horizontalPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs (Status + MediaType)
          Row(
            children: [
              // Status Filters
              _buildStatusPill(
                context: context,
                label: 'Watching',
                status: TrackedStatus.watching,
                currentStatus: viewState.status,
                onTap: () => viewNotifier.setStatus(TrackedStatus.watching),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(
                context: context,
                label: 'Plan to Watch',
                status: TrackedStatus.planning,
                currentStatus: viewState.status,
                onTap: () => viewNotifier.setStatus(TrackedStatus.planning),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(
                context: context,
                label: 'Completed',
                status: TrackedStatus.completed,
                currentStatus: viewState.status,
                onTap: () => viewNotifier.setStatus(TrackedStatus.completed),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(
                context: context,
                label: 'Paused',
                status: TrackedStatus.paused,
                currentStatus: viewState.status,
                onTap: () => viewNotifier.setStatus(TrackedStatus.paused),
              ),
              const Spacer(),

              // Type Filter
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildMediaTypeToggle(
                      context: context,
                      label: 'Anime',
                      isSelected: viewState.mediaType == MediaType.ANIME,
                      onTap: () => viewNotifier.setMediaType(MediaType.ANIME),
                    ),
                    _buildMediaTypeToggle(
                      context: context,
                      label: 'Manga',
                      isSelected: viewState.mediaType == MediaType.MANGA,
                      onTap: () => viewNotifier.setMediaType(MediaType.MANGA),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Library Grid / Empty View
          Expanded(
            child: libraryEntriesAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No entries in ${viewState.status.name}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 60, top: 4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: isWide ? 1.4 : 0.68,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final media = item.toUnifiedMedia();

                    return MediaCard(
                      title: item.title,
                      subtitle:
                          '${item.episodesWatched}/${item.episodes ?? "?"} ep',
                      tag: 'tv-lib-${item.providerId}',
                      imageUrl: item.cover,
                      score: item.score,
                      format: item.format,
                      status: item.status,
                      style: cardStyle,
                      onTap: () {
                        context.pushDetails(
                          mediaType: media.type,
                          media: media,
                          tag: 'tv-lib-${media.id}',
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading library: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required BuildContext context,
    required String label,
    required TrackedStatus status,
    required TrackedStatus currentStatus,
    required VoidCallback onTap,
  }) {
    final isSelected = status == currentStatus;
    final cs = Theme.of(context).colorScheme;

    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap();
            return null;
          },
        ),
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTypeToggle({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap();
            return null;
          },
        ),
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
