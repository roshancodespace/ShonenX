import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/presentation/widgets/library_filters.dart';
import 'package:shonenx/features/library/presentation/widgets/library_grid.dart';
import 'package:shonenx/features/library/providers/library_view_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    
    final mediaType = _tabController.index == 0 ? MediaType.ANIME : MediaType.MANGA;
    ref.read(libraryViewStateProvider.notifier).setMediaType(mediaType);
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(libraryViewStateProvider);
    
    // Ensure the tab matches the state if changed externally
    if (viewState.mediaType == MediaType.ANIME && _tabController.index != 0) {
      _tabController.animateTo(0);
    } else if (viewState.mediaType == MediaType.MANGA && _tabController.index != 1) {
      _tabController.animateTo(1);
    }

    return AppScaffold(
      subtitle: 'FROM LIBRARY',
      title: viewState.status.displayName.toUpperCase(),
      actions: [
        if (ref.watch(trackingPrefsProvider.select((s) => s.primaryTracker)) !=
                TrackerType.local &&
            ref.watch(trackerProfileProvider)[ref.watch(
                  trackingPrefsProvider.select((s) => s.primaryTracker),
                )] !=
                null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SegmentedButton<LibraryMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment<LibraryMode>(
                  value: LibraryMode.cloud,
                  icon: Icon(
                    viewState.mode == LibraryMode.cloud
                        ? Icons.cloud
                        : Icons.cloud_outlined,
                  ),
                  tooltip: 'Cloud Library',
                ),
                ButtonSegment<LibraryMode>(
                  value: LibraryMode.local,
                  icon: Icon(
                    viewState.mode == LibraryMode.local
                        ? Icons.folder
                        : Icons.folder_outlined,
                  ),
                  tooltip: 'Local Library',
                ),
              ],
              selected: {viewState.mode},
              onSelectionChanged: (Set<LibraryMode> newSelection) {
                ref
                    .read(libraryViewStateProvider.notifier)
                    .setMode(newSelection.first);
              },
            ),
          ),
        const SizedBox(width: 10),
      ],
      barBottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Anime'),
            Tab(text: 'Manga'),
          ],
        ),
      ),
      body: Column(
        children: const [
          LibraryFiltersWidget(),
          Expanded(child: LibraryGridWidget()),
        ],
      ),
    );
  }
}
