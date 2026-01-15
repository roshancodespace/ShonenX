import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/utils/misc.dart';
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
    with TickerProviderStateMixin {
  TabController? _controller;
  List<String> _statuses = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = ref.read(animeRepositoryProvider);
    final statuses = await repo.getSupportedStatuses();
    _statuses = [...statuses, 'favorites'];

    _controller = TabController(length: _statuses.length, vsync: this)
      ..addListener(() {
        if (_controller!.index != _index) {
          _index = _controller!.index;
          _fetch(_index);
        }
      });

    setState(() {});
    _fetch(0);
  }

  Future<void> _fetch(int i, {bool force = false, int page = 1}) async {
    if (_statuses.isEmpty) return;

    await ref
        .read(watchlistProvider.notifier)
        .fetchListForStatus(_statuses[i], force: force, page: page);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Your Library',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _controller,
          isScrollable: true,
          indicatorWeight: 3,
          onTap: (i) => _fetch(i),
          tabs: _statuses.map((s) => Tab(text: _label(s))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: _statuses.map((s) => _WatchlistTabView(status: s)).toList(),
      ),
    );
  }

  String _label(String s) {
    switch (s.toLowerCase()) {
      case 'current':
        return 'Watching';
      case 'planning':
        return 'Plan to Watch';
      default:
        return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }
  }
}

class _WatchlistTabView extends ConsumerWidget {
  final String status;
  const _WatchlistTabView({required this.status});

  int _columns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1400) return 6;
    if (w >= 1100) return 5;
    if (w >= 800) return 4;
    if (w >= 450) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);
    final cardStyle = ref.watch(uiSettingsProvider).cardStyle;
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);

    if (state.loadingStatuses.contains(status)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errors.containsKey(status)) {
      return _ErrorView(
        message: state.errors[status]!,
        onRetry: () => notifier.fetchListForStatus(status, force: true),
      );
    }

    final media = status == 'favorites'
        ? state.favorites.map((e) => e.media).toList()
        : state.listFor(status).map((e) => e.media).toList();

    if (media.isEmpty) return const _EmptyState();

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        final info = state.pageInfo[status];
        if (info != null &&
            info.hasNextPage &&
            !state.loadingStatuses.contains(status) &&
            n.metrics.pixels >= n.metrics.maxScrollExtent * 0.9) {
          notifier.fetchListForStatus(status, page: info.currentPage + 1);
          print('Fetching page ${info.currentPage + 1} for $status');
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => notifier.fetchListForStatus(status, force: true),
        child: ShonenXGridView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 120),
          crossAxisCount: _columns(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
          items: media.map((anime) {
            final tag = randomId();
            return AnimatedAnimeCard(
              anime: anime,
              tag: tag,
              mode: mode,
              onTap: () => navigateToDetail(context, anime, tag),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load list',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
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
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.archive_add,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'List is Empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some anime to track your progress!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
