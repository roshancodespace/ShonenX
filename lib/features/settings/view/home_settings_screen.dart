import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/home/model/home_section.dart';
import 'package:shonenx/features/settings/view_model/home_layout_notifier.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class HomeSettingsScreen extends ConsumerWidget {
  const HomeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(homeLayoutProvider);
    final notifier = ref.read(homeLayoutProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Home Layout'),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            tooltip: 'Add Watchlist Row',
            icon: const Icon(Iconsax.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
          IconButton(
            tooltip: 'Reset to Default',
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: notifier.reset,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 80),
        itemCount: layout.length,
        onReorder: notifier.move,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final elevation = Tween<double>(
                begin: 0,
                end: 8,
              ).evaluate(animation);
              return Material(
                elevation: elevation,
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final section = layout[index];
          final accent = _sectionColor(section.type, theme);

          return Padding(
            key: ValueKey(section.id),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Material(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Drag handle
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.drag_handle,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      // Accent bar
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getTypeLabel(section.type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: section.enabled,
                            onChanged: (_) => notifier.toggle(index),
                          ),
                          if (section.type == HomeSectionType.watchlist)
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close_rounded),
                              color: theme.colorScheme.error,
                              onPressed: () => notifier.delete(index),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTypeLabel(HomeSectionType type) {
    switch (type) {
      case HomeSectionType.spotlight:
        return 'Hero Section';
      case HomeSectionType.continueWatching:
        return 'Progress';
      case HomeSectionType.standard:
        return 'Standard';
      case HomeSectionType.watchlist:
        return 'Watchlist';
    }
  }

  Color _sectionColor(HomeSectionType type, ThemeData theme) {
    switch (type) {
      case HomeSectionType.spotlight:
        return Colors.orangeAccent;
      case HomeSectionType.continueWatching:
        return Colors.blueAccent;
      case HomeSectionType.watchlist:
        return Colors.greenAccent;
      case HomeSectionType.standard:
        return theme.colorScheme.primary;
    }
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(animeRepositoryProvider);
    final statuses = await repo.getSupportedStatuses();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Watchlist Row',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...statuses.map(
                (status) => ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(status.toUpperCase()),
                  trailing: const Icon(Iconsax.add),
                  onTap: () {
                    ref
                        .read(homeLayoutProvider.notifier)
                        .addWatchlistRow(status);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
