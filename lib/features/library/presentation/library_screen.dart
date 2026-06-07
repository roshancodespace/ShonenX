import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/library/providers/local_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import '../providers/library_view_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final TrackedStatus? status;

  const LibraryScreen({super.key, this.status});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewState = ref.watch(libraryViewStateProvider);
    final dynamicLibrary = ref.watch(dynamicLibraryProvider);
    final cardStyle = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return AppScaffold(
      subtitle: 'FROM LIBRARY',
      title: viewState.status.displayName.toUpperCase(),
      barBottom: PreferredSize(
        preferredSize: const Size.fromHeight(45),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: TrackedStatus.values
                    .where((s) => s != TrackedStatus.unknown)
                    .map((status) {
                      final isActive = viewState.status == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            status.displayName,
                            style: TextStyle(
                              color: isActive
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isActive,
                          selectedColor: theme.colorScheme.secondaryContainer,
                          checkmarkColor:
                              theme.colorScheme.onSecondaryContainer,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(libraryViewStateProvider.notifier)
                                  .setStatus(status);
                            }
                          },
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ),
      ),
      body: dynamicLibrary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('ERR: $err')),
        data: (entries) {
          if (entries.isEmpty) return const Center(child: Text('Empty List'));

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (ref.watch(
                        trackingPrefsProvider.select((s) => s.primaryTracker),
                      ) !=
                      TrackerType.local &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200) {
                ref
                    .read(cloudLibraryProvider(viewState.status).notifier)
                    .loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                if (ref.watch(
                      trackingPrefsProvider.select((s) => s.primaryTracker),
                    ) !=
                    TrackerType.local) {
                  ref
                      .read(cloudLibraryProvider(viewState.status).notifier)
                      .refresh();
                } else {
                  ref.invalidate(localLibraryListProvider(viewState.status));
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: cardStyle.layout.width + 10,
                    mainAxisExtent: cardStyle.layout.height,
                    childAspectRatio: cardStyle.layout.aspectRatio,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: entries.length + 5,

                  itemBuilder: (context, index) {
                    if (index >= entries.length) {
                      return const SizedBox();
                    }

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
      ),
    );
  }
}
