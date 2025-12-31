import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/features/watchlist/view/widget/shonenx_gridview.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';
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
  int _currentIndex = 0;

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
        if (_tabController!.index != _currentIndex) {
          setState(() {
            _currentIndex = _tabController!.index;
          });
          _fetchDataForIndex(_currentIndex);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Your Library',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    if (s.toLowerCase() == 'current') return 'Watching';
    if (s.toLowerCase() == 'planning') return 'Plan to Watch';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

class _WatchlistTabView extends ConsumerWidget {
  final String status;
  const _WatchlistTabView({required this.status});

  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 1400
        ? 6
        : width >= 1100
            ? 5
            : width >= 800
                ? 4
                : width >= 450
                    ? 3
                    : 2; // Keep at least 2 columns like BrowseScreen
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);
    final cardStyle = ref.watch(uiSettingsProvider).cardStyle;
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);

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
      return const _EmptyState();
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          crossAxisCount: _getColumnCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.70, // Slightly taller for better card look
          items: mediaList.map((anime) {
            final tag = generateId().toString();
            return AnimatedAnimeCard(
              anime: anime,
              tag: "$tag${anime.id}",
              mode: mode,
              onTap: () => navigateToDetail(context, anime, "$tag${anime.id}"),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              "Failed to load list",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.archive_add,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'List is Empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some anime to track your progress!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}
