import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_mixin.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/history/providers/history_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/app_button_group.dart';
import 'package:shonenx/shared/widgets/app_card_group.dart';
import 'package:shonenx/shared/widgets/app_chip.dart';
import 'package:shonenx/shared/widgets/app_empty_state.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class ContinueHistoryScreen extends ConsumerStatefulWidget {
  final MediaType type;

  const ContinueHistoryScreen({super.key, required this.type});

  @override
  ConsumerState<ContinueHistoryScreen> createState() =>
      _ContinueHistoryScreenState();
}

class _ContinueHistoryScreenState extends ConsumerState<ContinueHistoryScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelected(bool isAnime) async {
    final toDelete = _selectedIds.toList();
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    await ref.read(historyRepositoryProvider).deleteByMediaIds(toDelete);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.historyDeletedCount(toDelete.length)),
        ),
      );
    }
  }

  void _showMediaOptionsBottomSheet(
    BuildContext context,
    String id,
    String title,
    String imageUrl,
    bool isAnime,
  ) {
    AppBottomSheet.show(
      context: context,
      title: title,
      child: AppCardGroup(
        padding: EdgeInsets.zero,
        children: [
          AppCardSurface(
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              context.pushContinueHistoryItem(widget.type, id);
            },
            child: ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: Text(
                isAnime
                    ? context.l10n.homeContinueWatching
                    : context.l10n.homeContinueReading,
              ),
            ),
          ),
          AppCardSurface(
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              context.pushDetails(
                mediaType: widget.type,
                media: UnifiedMedia(
                  id: id,
                  title: MediaTitle(english: title),
                  type: widget.type,
                  cover: imageUrl,
                ),
              );
            },
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(context.l10n.historyOpenDetails),
            ),
          ),
          AppCardSurface(
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _isSelectionMode = true;
                _selectedIds.add(id);
              });
            },
            child: ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: Text(context.l10n.historySelectItems),
            ),
          ),
          AppCardSurface(
            padding: EdgeInsets.zero,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);
              await ref.read(historyRepositoryProvider).deleteByMediaId(id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(this.context.l10n.historyRemoved)),
                );
              }
            },
            child: ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.l10n.commonRemove,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSelectionHeader(List<dynamic> filtered, bool isAnime) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.l10n.historySearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),
          if (_isSelectionMode) ...[
            const SizedBox(width: 8),
            AppButton(
              label: _selectedIds.length == filtered.length
                  ? context.l10n.historyDeselectAll
                  : context.l10n.historySelectAll,
              variant: AppButtonVariant.tonal,
              size: AppButtonSize.small,
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == filtered.length) {
                    _selectedIds.clear();
                  } else {
                    for (final e in filtered) {
                      _selectedIds.add(e.mediaId);
                    }
                  }
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnime = widget.type == MediaType.ANIME;
    final uiState = ref.watch(uiPrefsProvider);
    final style = uiState.cardStyle;
    final isWideMode = uiState.isMediaCardWide(style.name);
    final scale = ref.watch(themePrefsProvider).uiScaleFactor;
    final layout = style.getScaledLayout(scale, isWideMode: isWideMode);
    final theme = Theme.of(context);

    final historyAsync = ref
        .watch(historyPerMediaProvider((mediaType: widget.type.id, limit: 100)))
        .whenData((data) => data.toList());

    return AppScaffold(
      title: _isSelectionMode
          ? context.l10n.itemsSelected(_selectedIds.length)
          : (isAnime
                ? context.l10n.homeContinueWatching
                : context.l10n.homeContinueReading),
      subtitle: _isSelectionMode
          ? context.l10n.historySelectItemsToDelete
          : context.l10n.historyPickUpWhereYouLeftOff,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AppActionButtonGroup(
            height: 36,
            items: _isSelectionMode
                ? [
                    AppActionItem(
                      icon: Icons.delete_outline_rounded,
                      tooltip: context.l10n.historyDeleteSelected,
                      onTap: () {
                        if (_selectedIds.isNotEmpty) {
                          _deleteSelected(isAnime);
                        }
                      },
                    ),
                    AppActionItem(
                      icon: Icons.close_rounded,
                      tooltip: context.l10n.historyCancelSelection,
                      onTap: () => setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      }),
                    ),
                  ]
                : [
                    AppActionItem(
                      icon: Icons.checklist_rounded,
                      tooltip: context.l10n.historySelectItems,
                      onTap: () => setState(() => _isSelectionMode = true),
                    ),
                  ],
          ),
        ),
      ],
      body: historyAsync.when(
        loading: () => const Center(
          child: AppProgressIndicator(type: AppProgressType.circular),
        ),
        error: (err, _) => AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load history',
          subtitle: err.toString(),
        ),
        data: (entries) {
          final filtered = _searchQuery.isEmpty
              ? entries
              : entries.where((e) {
                  final title = e.mediaTitle;
                  return title.toLowerCase().contains(_searchQuery);
                }).toList();

          if (entries.isEmpty) {
            return AppEmptyState(
              icon: isAnime
                  ? Icons.play_circle_outline_rounded
                  : Icons.auto_stories_rounded,
              title: context.l10n.historyEmpty,
              subtitle: context.l10n.historyPickUpWhereYouLeftOff,
            );
          }

          return Column(
            children: [
              _buildSearchAndSelectionHeader(filtered, isAnime),
              Expanded(
                child: filtered.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching history items',
                        subtitle: 'Try a different search query.',
                      )
                    : GridView.builder(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
                          minCrossAxisExtent: layout.width,
                          childAspectRatio: layout.aspectRatio,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final String id = entry.mediaId;
                          final String title = entry.mediaTitle;
                          final String imageUrl =
                              entry.cover ??
                              (isAnime ? entry.thumbnailUrl : null) ??
                              '';
                          final isSelected = _selectedIds.contains(id);

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    GlobalUI.uiRoundness,
                                  ),
                                  border: _isSelectionMode && isSelected
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2.5,
                                        )
                                      : null,
                                ),
                                child: AnimatedOpacity(
                                  opacity: _isSelectionMode && !isSelected
                                      ? 0.65
                                      : 1.0,
                                  duration: const Duration(milliseconds: 180),
                                  child: MediaCard(
                                    media: UnifiedMedia(
                                      id: id,
                                      type: isAnime
                                          ? MediaType.ANIME
                                          : MediaType.MANGA,
                                      title: MediaTitle(english: title),
                                      cover: imageUrl,
                                    ),
                                    tag: 'ch-$id',
                                    style: style,
                                    onSecondaryTap: () {
                                      if (!_isSelectionMode) {
                                        _showMediaOptionsBottomSheet(
                                          context,
                                          id,
                                          title,
                                          imageUrl,
                                          isAnime,
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_isSelectionMode) {
                                        _showMediaOptionsBottomSheet(
                                          context,
                                          id,
                                          title,
                                          imageUrl,
                                          isAnime,
                                        );
                                      } else {
                                        _toggleSelection(id);
                                      }
                                    },
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleSelection(id);
                                      } else {
                                        context.pushContinueHistoryItem(
                                          widget.type,
                                          id,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (_isSelectionMode)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: IgnorePointer(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                          width: 1.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color:
                                                  theme.colorScheme.onPrimary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ContinueHistoryItemsScreen extends ConsumerStatefulWidget {
  final MediaType type;
  final String mediaId;

  const ContinueHistoryItemsScreen({
    super.key,
    required this.type,
    required this.mediaId,
  });

  @override
  ConsumerState<ContinueHistoryItemsScreen> createState() =>
      _ContinueHistoryItemsScreenState();
}

class _ContinueHistoryItemsScreenState
    extends ConsumerState<ContinueHistoryItemsScreen>
    with ContinueMediaMixin<ContinueHistoryItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final isAnime = widget.type == MediaType.ANIME;

    final historyAsync = ref
        .watch(historyForMediaProvider(widget.mediaId))
        .whenData((data) => data.toList());

    return AppScaffold(
      body: historyAsync.when(
        loading: () => const Center(
          child: AppProgressIndicator(type: AppProgressType.circular),
        ),
        error: (err, _) => AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load history',
          subtitle: err.toString(),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return AppEmptyState(
              icon: isAnime
                  ? Icons.play_circle_outline_rounded
                  : Icons.auto_stories_rounded,
              title: 'No history found',
              subtitle: context.l10n.historyPickUpWhereYouLeftOff,
            );
          }

          final prefsAsync = ref.watch(uiPrefsProvider);
          final style = isAnime
              ? prefsAsync.continueWatchingStyle
              : prefsAsync.continueReadingStyle;

          final isWideMode = isAnime
              ? prefsAsync.isContinueWatchingWide(style.name)
              : prefsAsync.isContinueReadingWide(style.name);

          final layout = style.getLayout(
            isContinueWatching: isAnime,
            isContinueReading: !isAnime,
            isWideMode: isWideMode,
          );

          final firstEntry = entries.first;
          final title = firstEntry.mediaTitle;
          final bannerUrl =
              firstEntry.banner ?? firstEntry.cover ?? firstEntry.thumbnailUrl;
          final coverUrl = firstEntry.cover ?? bannerUrl;
          final imageUrl = bannerUrl ?? coverUrl ?? '';

          int totalWatched = entries.length;
          String totalTimeStr = '';
          if (isAnime) {
            final totalMillis = entries.fold<int>(
              0,
              (sum, e) => sum + (e.total.toInt()),
            );
            final duration = Duration(milliseconds: totalMillis);
            final hours = duration.inHours;
            final mins = (duration.inMinutes % 60);
            totalTimeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
          } else {
            final totalPages = entries.fold<int>(
              0,
              (sum, e) => sum + (e.total.toInt()),
            );
            totalTimeStr = '$totalPages Pages';
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                leadingWidth: 64,
                leading: Center(
                  child: AppActionButtonGroup(
                    outlined: false,
                    height: 38,
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                    items: [
                      AppActionItem(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: context.l10n.commonBack,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black,
                                Colors.black,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: SmartImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            AppChipGroup(
                              children: [
                                AppChip(
                                  icon: isAnime
                                      ? Icons.play_circle_outline_rounded
                                      : Icons.auto_stories_rounded,
                                  label: isAnime
                                      ? '$totalWatched Episodes'
                                      : '$totalWatched Chapters',
                                ),
                                AppChip(
                                  icon: Icons.timer_outlined,
                                  label: totalTimeStr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isWideMode
                        ? layout.width * 1.5
                        : layout.width * 1.2,
                    childAspectRatio: layout.width / layout.height,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];

                    if (isAnime) {
                      final duration = entry.total;
                      final pos = entry.progress;
                      final progress = (duration > 0) ? (pos / duration) : 0.0;

                      return ContinueWatchingItem(
                        entry: entry,
                        progress: progress,
                        style: style,
                      );
                    } else {
                      final total = entry.total;
                      final current = entry.progress;
                      final progress = (total > 0) ? (current / total) : 0.0;

                      return ContinueReadingItem(
                        entry: entry,
                        progress: progress,
                        style: style,
                      );
                    }
                  }, childCount: entries.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
