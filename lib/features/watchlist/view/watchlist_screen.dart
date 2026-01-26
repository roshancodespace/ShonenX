import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/misc.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/features/watchlist/view/widget/watchlist_grid_view.dart';
import 'package:shonenx/features/watchlist/view/widget/watchlist_states_widgets.dart';
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
    if (_statuses.length <= i) return;

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
    final auth = ref.watch(authProvider);
    final isLocal = ref.watch(watchlistProvider.select((s) => s.isLocal));

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
        actions: [
          if (auth.isAniListAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _ModeSwitch(isLocal: isLocal),
            ),
        ],
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
      case 'watching':
      case 'current':
        return 'Watching';
      case 'completed':
        return 'Completed';
      case 'on_hold':
      case 'onhold':
        return 'On Hold';
      case 'dropped':
        return 'Dropped';
      case 'plan_to_watch':
      case 'planning':
        return 'Plan to Watch';
      case 'favorites':
        return 'Favorites';
      default:
        return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }
  }
}

class _ModeSwitch extends ConsumerWidget {
  final bool isLocal;
  const _ModeSwitch({required this.isLocal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchOption(
            label: 'Cloud',
            isSelected: !isLocal,
            onTap: () => ref.read(watchlistProvider.notifier).setMode(false),
          ),
          _SwitchOption(
            label: 'Local',
            isSelected: isLocal,
            onTap: () => ref.read(watchlistProvider.notifier).setMode(true),
          ),
        ],
      ),
    );
  }
}

class _SwitchOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwitchOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _WatchlistTabView extends ConsumerWidget {
  final String status;
  const _WatchlistTabView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);
    final mode = ref.watch(uiSettingsProvider).cardStyle;

    final media = status == 'favorites'
        ? state.favorites.map((e) => e.media).toList()
        : state.listFor(status).map((e) => e.media).toList();

    final isLoading = state.loadingStatuses.contains(status);

    if (isLoading && media.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errors.containsKey(status) && media.isEmpty) {
      return WatchlistErrorView(
        message: state.errors[status]!,
        onRetry: () => notifier.fetchListForStatus(status, force: true),
      );
    }

    if (media.isEmpty) return const WatchlistEmptyState();

    return WatchlistGridView(
      itemCount: media.length + (isLoading ? 1 : 0),
      onRefresh: () async => notifier.fetchListForStatus(status, force: true),
      onScrollNotification: (n) {
        // Pagination only for Remote
        if (!state.isLocal) {
          final info = state.pageInfo[status];
          if (info != null &&
              info.hasNextPage &&
              !isLoading &&
              n.metrics.pixels >= n.metrics.maxScrollExtent * 0.9) {
            notifier.fetchListForStatus(status, page: info.currentPage + 1);
          }
        }
        return false;
      },
      itemBuilder: (context, index) {
        if (index == media.length) {
          return const WatchlistLoadingIndicator();
        }
        final anime = media[index];
        final tag = randomId();
        return AnimatedAnimeCard(
          anime: anime,
          tag: tag,
          mode: mode,
          onTap: () => navigateToDetail(context, anime, tag),
        );
      },
    );
  }
}
