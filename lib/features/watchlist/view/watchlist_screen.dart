import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/features/watchlist/view/widget/shonenx_gridview.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<WatchlistStatus> _statuses = WatchlistStatus.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);

    // Fetch data for the initial tab.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDataForIndex(0));

    // Add a listener to fetch data when the user swipes to a new tab.
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchDataForIndex(_tabController.index);
      }
    });
  }

  void _fetchDataForIndex(int index, {bool force = false}) {
    final status = _statuses[index];
    ref
        .read(watchlistProvider.notifier)
        .fetchListForStatus(status, force: force);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) => _fetchDataForIndex(index), // Also fetch on tap
          tabs: _statuses
              .map((s) =>
                  Tab(text: s.name[0].toUpperCase() + s.name.substring(1)))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          return _WatchlistTabView(status: status);
        }).toList(),
      ),
    );
  }
}

// A dedicated, reusable widget for displaying the content of a single tab.
class _WatchlistTabView extends ConsumerWidget {
  final WatchlistStatus status;

  const _WatchlistTabView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to rebuild when state changes.
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);

    // Check loading state for THIS specific tab.
    if (state.loadingStatuses.contains(status)) {
      return const Center(child: CircularProgressIndicator());
    }

    // Check error state for THIS specific tab.
    if (state.errors.containsKey(status)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Failed to load list.\n${state.errors[status]}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.fetchListForStatus(status, force: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Get the correct data list for this tab.
    final List<Media> mediaList = _getMediaForStatus(state, status);

    if (mediaList.isEmpty) {
      return Center(child: Text('No anime in this list.'));
    }

    // The actual list UI with pull-to-refresh.
    return RefreshIndicator(
      onRefresh: () => notifier.fetchListForStatus(status, force: true),
      child: ShonenXGridView (
          physics: AlwaysScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.75,
          items: mediaList.map((anime) {
            final tag = generateId().toString();
            return AnimatedAnimeCard(
                anime: anime,
                tag: tag + (anime.id.toString()),
                onTap: () => navigateToDetail(context, anime, tag));
          }).toList()),
    );
  }

  // Helper to extract the right list of Media from the state.
  List<Media> _getMediaForStatus(WatchListState state, WatchlistStatus status) {
    switch (status) {
      case WatchlistStatus.current:
        return state.current.map((e) => e.media).toList();
      case WatchlistStatus.completed:
        return state.completed.map((e) => e.media).toList();
      case WatchlistStatus.paused:
        return state.paused.map((e) => e.media).toList();
      case WatchlistStatus.dropped:
        return state.dropped.map((e) => e.media).toList();
      case WatchlistStatus.planning:
        return state.planning.map((e) => e.media).toList();
      case WatchlistStatus.favorites:
        return state.favorites;
    }
  }
}
