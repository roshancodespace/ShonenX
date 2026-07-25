import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/presentation/widgets/library_filters.dart';
import 'package:shonenx/features/library/presentation/widgets/library_grid.dart';
import 'package:shonenx/features/library/providers/library_view_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/media_switcher_overlay.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<MediaType> _supportedMediaTypes = [];

  @override
  void initState() {
    super.initState();
    _supportedMediaTypes = ref.read(primaryTrackerProvider).supportedMediaTypes;
    final initMediaType = ref.read(libraryViewStateProvider).mediaType;
    int initIndex = _supportedMediaTypes.indexOf(initMediaType);
    if (initIndex == -1) initIndex = 0;

    _tabController = TabController(
      length: _supportedMediaTypes.length,
      vsync: this,
      initialIndex: initIndex,
    );
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _attachOverlay();
      }
    });
  }

  void _attachOverlay() {
    Future.microtask(() {
      try {
        ref
            .read(navBarProvider.notifier)
            .attachTop(
              MediaSwitcherOverlay(
                controller: _tabController,
                supportedTypes: _supportedMediaTypes,
              ),
              branchIndex: 2,
            );
      } catch (_) {}
    });
  }

  void _rebuildTabController(List<MediaType> newTypes) {
    if (!mounted) return;
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    setState(() {
      _supportedMediaTypes = newTypes;
      _tabController = TabController(length: newTypes.length, vsync: this);
      _tabController.addListener(_handleTabChange);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachOverlay();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      try {
        ref.read(navBarProvider.notifier).clearTop(branchIndex: 2);
      } catch (_) {}
    });
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index < 0 ||
        _tabController.index >= _supportedMediaTypes.length)
      return;

    final mediaType = _supportedMediaTypes[_tabController.index];
    ref.read(libraryViewStateProvider.notifier).setMediaType(mediaType);
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(libraryViewStateProvider);

    // Watch for tracker changes
    ref.listen(primaryTrackerProvider, (previous, next) {
      if (previous?.supportedMediaTypes != next.supportedMediaTypes) {
        _rebuildTabController(next.supportedMediaTypes);
      }
    });

    final targetIndex = _supportedMediaTypes.indexOf(viewState.mediaType);
    if (targetIndex != -1 && _tabController.index != targetIndex) {
      _tabController.animateTo(targetIndex);
    }

    return AppScaffold(
      title: viewState.status.getLabelForMedia(viewState.mediaType),
      subtitle: 'From Library',
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
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
                minimumSize: WidgetStateProperty.all(const Size(48, 40)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
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
      body: Column(
        children: const [
          LibraryFiltersWidget(),
          Expanded(child: LibraryGridWidget()),
        ],
      ),
    );
  }
}
