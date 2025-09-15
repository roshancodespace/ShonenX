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
  final _statuses = WatchlistStatus.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataForIndex(0);
    });

    // Fetch when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchDataForIndex(_tabController.index);
      }
    });
  }

  void _fetchDataForIndex(int index, {bool force = false}) {
    ref.read(watchlistProvider.notifier).fetchListForStatus(
          _statuses[index],
          force: force,
        );
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
          onTap: (i) => _fetchDataForIndex(i),
          tabs: _statuses.map((s) => Tab(text: _capitalize(s.name))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses
            .map((status) => _WatchlistTabView(status: status))
            .toList(),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _WatchlistTabView extends ConsumerWidget {
  final WatchlistStatus status;
  const _WatchlistTabView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);

    // Loading
    if (state.loadingStatuses.contains(status)) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (state.errors.containsKey(status)) {
      return _ErrorView(
        message: state.errors[status]!,
        onRetry: () => notifier.fetchListForStatus(status, force: true),
      );
    }

    // Data
    final mediaList = _extractMedia(state, status);
    if (mediaList.isEmpty) {
      return const Center(child: Text('No anime in this list.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent * 0.9) {
          final pageInfo = state.pageInfo[status];
          if (pageInfo != null &&
              pageInfo.hasNextPage &&
              !state.loadingStatuses.contains(status)) {
            notifier.fetchListForStatus(status, page: pageInfo.currentPage + 1);
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () =>
            notifier.fetchListForStatus(status, force: true, page: 1),
        child: ShonenXGridView(
          physics: const AlwaysScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.75,
          items: mediaList.map((anime) {
            final tag = generateId().toString();
            return AnimatedAnimeCard(
              anime: anime,
              tag: "$tag${anime.id}",
              onTap: () => navigateToDetail(context, anime, tag),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Media> _extractMedia(WatchListState state, WatchlistStatus status) {
    if (status == WatchlistStatus.favorites) return state.favorites;
    return (state.lists[status] ?? []).map((e) => e.media).toList();
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Failed to load list.\n$message"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
