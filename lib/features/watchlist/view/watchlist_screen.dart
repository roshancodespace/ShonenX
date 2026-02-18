import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/shared/providers/settings/ui_notifier.dart';
import 'package:shonenx/shared/ui/shonenx_gridview.dart';
import 'package:shonenx/features/watchlist/view/widget/watchlist_states_widgets.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

import 'package:iconsax/iconsax.dart';
import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/details/view_model/local_tracker_notifier.dart';

class WatchlistSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
    }
  }

  void clear() => state = {};

  void selectAll(List<String> ids) {
    state = {...state, ...ids};
  }
}

final watchlistSelectionProvider =
    NotifierProvider<WatchlistSelectionNotifier, Set<String>>(
      WatchlistSelectionNotifier.new,
    );

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
          // Clear selection when changing tabs
          ref.read(watchlistSelectionProvider.notifier).clear();
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

  Future<void> _deleteSelected() async {
    final selectedIds = ref.read(watchlistSelectionProvider);
    if (selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected?'),
        content: Text(
          'Are you sure you want to delete ${selectedIds.length} items? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final auth = ref.read(authProvider);
    final isLocal = ref.read(watchlistProvider).isLocal;

    try {
      int successCount = 0;
      for (final idStr in selectedIds) {
        final id = int.tryParse(idStr);
        if (id == null) continue;

        if (!isLocal && auth.isAniListAuthenticated) {
          final success = await ref
              .read(anilistServiceProvider)
              .deleteUserAnimeList(id);
          if (success) successCount++;
        } else if (isLocal) {
          await ref.read(localTrackerProvider.notifier).deleteEntry(idStr);
          successCount++;
        }
      }

      if (successCount > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted $successCount items')),
          );
        }
      }

      ref.read(watchlistSelectionProvider.notifier).clear();
      // Refresh current list
      _fetch(_index, force: true);
    } catch (e) {
      AppLogger.e('Failed to delete items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final isLocal = ref.watch(watchlistProvider.select((s) => s.isLocal));
    final selected = ref.watch(watchlistSelectionProvider);
    final isSelectionMode = selected.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
                onPressed: () =>
                    ref.read(watchlistSelectionProvider.notifier).clear(),
                icon: const Icon(Icons.close),
              )
            : null,
        title: isSelectionMode
            ? Text(
                '${selected.length} Selected',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(
                'Your Library',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (isSelectionMode)
            IconButton(
              onPressed: _deleteSelected,
              icon: const Icon(Iconsax.trash, color: Colors.red),
            )
          else if (auth.isAniListAuthenticated)
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
    final dim = mode.getDimensions(context);

    // Listen to selection changes to rebuild
    final selectedIds = ref.watch(watchlistSelectionProvider);
    final isSelectionMode = selectedIds.isNotEmpty;

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

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
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
      child: RefreshIndicator(
        onRefresh: () async => notifier.fetchListForStatus(status, force: true),
        child: ShonenXGridView(
          itemCount: media.length + (isLoading ? 1 : 0),
          crossAxisExtent: dim.width,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          padding: EdgeInsets.fromLTRB(10, 10, 10, 100),
          physics: const BouncingScrollPhysics(),
          childAspectRatio: dim.width / dim.height,
          itemBuilder: (context, index) {
            if (index == media.length) {
              return const WatchlistLoadingIndicator();
            }
            final anime = media[index];
            final tag = 'watchlist-$status-${anime.id}';
            final isSelected = selectedIds.contains(anime.id);

            return GestureDetector(
              onLongPress: () {
                ref.read(watchlistSelectionProvider.notifier).toggle(anime.id);
              },
              onTap: () {
                if (isSelectionMode) {
                  ref
                      .read(watchlistSelectionProvider.notifier)
                      .toggle(anime.id);
                } else {
                  navigateToDetail(context, anime, tag);
                }
              },
              child: Stack(
                children: [
                  AnimeCard(anime: anime, tag: tag, mode: mode),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
