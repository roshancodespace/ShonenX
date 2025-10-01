import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/features/watchlist/view/widget/shonenx_gridview.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> _statuses = [];

  @override
  void initState() {
    super.initState();
    _initStatuses();
  }

  Future<void> _initStatuses() async {
    final repo = ref.read(animeRepositoryProvider);
    final supportedStatuses = await repo.getSupportedStatuses();

    // Always include "favorites"
    _statuses = [...supportedStatuses, 'favorites'];

    setState(() {
      _tabController = TabController(length: _statuses.length, vsync: this);

      // Initial fetch for first tab
      _fetchDataForIndex(0);

      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) {
          _fetchDataForIndex(_tabController!.index);
        }
      });
    });
  }

  void _fetchDataForIndex(int index, {bool force = false}) {
    if (_statuses.isEmpty) return;
    final status = _statuses[index];
    ref
        .read(watchlistProvider.notifier)
        .fetchListForStatus(status, force: force);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (i) => _fetchDataForIndex(i),
          tabs: _statuses.map((s) => Tab(text: _capitalize(s))).toList(),
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
  final String status;
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
        final pageInfo = state.pageInfo[status];
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 &&
            pageInfo != null &&
            pageInfo.hasNextPage &&
            !state.loadingStatuses.contains(status)) {
          notifier.fetchListForStatus(status, page: pageInfo.currentPage + 1);
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

  List<Media> _extractMedia(WatchListState state, String status) {
    if (status == 'favorites') return state.favorites;
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
          Text("Failed to load list.\n$message", textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
