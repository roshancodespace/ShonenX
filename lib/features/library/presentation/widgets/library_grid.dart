import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/library/providers/library_view_provider.dart';
import 'package:shonenx/features/library/providers/local_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/core/utils/responsive.dart';

class LibraryGridWidget extends ConsumerWidget {
  const LibraryGridWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(libraryViewStateProvider);
    final dynamicLibrary = ref.watch(dynamicLibraryProvider);
    final cardStyle = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return dynamicLibrary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('ERR: $err')),
      data: (entries) {
        if (entries.isEmpty) return const Center(child: Text('Empty List'));

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            final primaryTracker = ref.read(
              trackingPrefsProvider.select((s) => s.primaryTracker),
            );
            final isCloudLoggedIn =
                ref.read(trackerProfileProvider)[primaryTracker] != null;
            final isCloud =
                viewState.mode == LibraryMode.cloud &&
                primaryTracker != TrackerType.local &&
                isCloudLoggedIn;

            if (isCloud &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
              ref
                  .read(
                    cloudLibraryProvider((
                      status: viewState.status,
                      trackerType: null,
                      mediaType: viewState.mediaType,
                    )).notifier,
                  )
                  .loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              final primaryTracker = ref.read(
                trackingPrefsProvider.select((s) => s.primaryTracker),
              );
              final isCloudLoggedIn =
                  ref.read(trackerProfileProvider)[primaryTracker] != null;
              final isCloud =
                  viewState.mode == LibraryMode.cloud &&
                  primaryTracker != TrackerType.local &&
                  isCloudLoggedIn;

              if (isCloud) {
                ref
                    .read(
                      cloudLibraryProvider((
                        status: viewState.status,
                        trackerType: null,
                        mediaType: viewState.mediaType,
                      )).notifier,
                    )
                    .refresh();
              } else {
                ref.invalidate(
                  localLibraryListProvider((
                    status: viewState.status,
                    mediaType: viewState.mediaType,
                  )),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 200),
                gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
                  minCrossAxisExtent: cardStyle.layout.width,
                  childAspectRatio: cardStyle.layout.aspectRatio,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];

                  return MediaCard(
                    title: entry.title,
                    tag: 'library__${viewState.status.id}_${entry.id}_$index',
                    imageUrl: entry.cover,
                    style: cardStyle,
                    onTap: () {
                      context.push(
                        '/details/${entry.type}',
                        extra: entry.toUnifiedMedia(),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
