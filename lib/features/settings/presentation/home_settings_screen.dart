import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class HomeSettingsScreen extends ConsumerWidget {
  const HomeSettingsScreen({super.key});

  Widget _buildSourceModeBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.tertiary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source Discovery Mode Active',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Content extensions only support a single Trending feed. Switch to Tracker Discovery Mode to unlock custom categories (Popular, Upcoming, Top Rated).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer.withOpacity(
                      0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeSections = ref.watch(userHomeLayoutProvider);
    final isSourceMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode == MetadataMode.source),
    );
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Home Settings',
      body: Column(
        children: [
          if (isSourceMode) _buildSourceModeBanner(context),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              buildDefaultDragHandles: false,
              itemCount: homeSections.length,
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(userHomeLayoutProvider.notifier)
                    .reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final section = homeSections[index];
                final isDisabled = section.disabled;
                final mediaType = section.targetMediaType ?? MediaType.ANIME;

                IconData getSectionIcon() {
                  switch (section.type) {
                    case HomeSectionType.continueMedia:
                      return mediaType == MediaType.ANIME
                          ? Icons.play_circle_outline_rounded
                          : Icons.menu_book_rounded;
                    case HomeSectionType.libraryStatus:
                      return Icons.collections_bookmark_outlined;
                    case HomeSectionType.discovery:
                      switch (section.trackerCategory) {
                        case TrackerCategory.popular:
                        case TrackerCategory.popularThisSeason:
                          return Icons.star_outline_rounded;
                        case TrackerCategory.topRated:
                          return Icons.emoji_events_outlined;
                        case TrackerCategory.upcoming:
                          return Icons.upcoming_outlined;
                        case TrackerCategory.recentlyUpdated:
                          return Icons.update_rounded;
                        case TrackerCategory.trending:
                        default:
                          return Icons.whatshot_outlined;
                      }
                  }
                }

                String getSubtitle() {
                  switch (section.type) {
                    case HomeSectionType.continueMedia:
                      return '${mediaType.displayName} • Continue Progress';
                    case HomeSectionType.libraryStatus:
                      final statusLabel =
                          section.libraryStatus?.getLabelForMedia(mediaType) ??
                          'Library';
                      final trackerName =
                          section.targetTracker?.displayName ?? 'Auto Source';
                      return '${mediaType.displayName} • $statusLabel ($trackerName)';
                    case HomeSectionType.discovery:
                      final catLabel =
                          section.trackerCategory?.label ?? 'Trending';
                      return '${mediaType.displayName} • $catLabel';
                  }
                }

                return SettingsSwitchTile(
                  key: ValueKey(section.id),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        getSectionIcon(),
                        color: isDisabled
                            ? theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              )
                            : theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  title: section.title,
                  subtitle: getSubtitle(),
                  value: !isDisabled,
                  onChanged: (value) => ref
                      .read(userHomeLayoutProvider.notifier)
                      .updateSection(section.copyWith(disabled: !value)),
                  onInfoCallback: () {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      builder: (_) => _SectionOptionsSheet(section: section),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            ref.read(userHomeLayoutProvider.notifier).reset();
          },
          icon: const Icon(Icons.restore_rounded),
          tooltip: 'Reset',
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _AddSectionSheet(existingSections: homeSections),
            );
          },
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add Section',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SectionOptionsSheet extends ConsumerWidget {
  final HomeSection section;

  const _SectionOptionsSheet({required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBottomSheet(
      title: 'Section Options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsActionTile(
            icon: Icons.edit_rounded,
            title: 'Edit',
            onTap: () {
              context.pop();
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (_) => _EditSectionSheet(section: section),
              );
            },
          ),
          SettingsActionTile(
            icon: Icons.delete_outline_rounded,
            title: 'Delete',
            isDestructive: true,
            onTap: () {
              context.pop();
              ref
                  .read(userHomeLayoutProvider.notifier)
                  .removeSection(section.id);
            },
          ),
        ],
      ),
    );
  }
}

class _EditSectionSheet extends ConsumerStatefulWidget {
  final HomeSection section;

  const _EditSectionSheet({required this.section});

  @override
  ConsumerState<_EditSectionSheet> createState() => _EditSectionSheetState();
}

class _EditSectionSheetState extends ConsumerState<_EditSectionSheet> {
  late final TextEditingController _titleController;
  late HomeSectionType _selectedType;
  late MediaType _selectedMediaType;
  TrackerCategory? _selectedCategory;
  TrackedStatus? _selectedStatus;
  TrackerType? _targetTracker;
  bool _titleModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    _selectedType = widget.section.type;
    _selectedMediaType = widget.section.targetMediaType ?? MediaType.ANIME;
    _selectedCategory =
        widget.section.trackerCategory ?? TrackerCategory.trending;
    _selectedStatus = widget.section.libraryStatus;
    _targetTracker = widget.section.targetTracker;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _updateAutoTitle() {
    if (_titleModified) return;

    String newTitle = '';
    switch (_selectedType) {
      case HomeSectionType.discovery:
        final categoryLabel = _selectedCategory?.label ?? 'Discovery';
        newTitle = '$categoryLabel ${_selectedMediaType.displayName}';
        break;
      case HomeSectionType.continueMedia:
        newTitle = _selectedMediaType == MediaType.ANIME
            ? 'Continue Watching'
            : 'Continue Reading';
        break;
      case HomeSectionType.libraryStatus:
        newTitle = 'My ${_selectedStatus?.displayName ?? 'Library'}';
        break;
    }
    _titleController.text = newTitle;
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    ref
        .read(userHomeLayoutProvider.notifier)
        .updateSection(
          widget.section.copyWith(
            title: title,
            type: _selectedType,
            targetMediaType: _selectedMediaType,
            trackerCategory: _selectedCategory,
            libraryStatus: _selectedStatus,
            targetTracker: _targetTracker,
            clearTargetTracker: _targetTracker == null,
          ),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSourceMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode == MetadataMode.source),
    );

    return AppBottomSheet(
      title: 'Edit Section',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<MediaType>(
            initialValue: _selectedMediaType,
            decoration: InputDecoration(
              labelText: 'Media Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: MediaType.ANIME, child: Text('Anime')),
              DropdownMenuItem(value: MediaType.MANGA, child: Text('Manga')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedMediaType = val;
                  _updateAutoTitle();
                });
              }
            },
          ),
          const SizedBox(height: 16),

          if (_selectedType == HomeSectionType.discovery) ...[
            DropdownButtonFormField<TrackerCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                helperText: isSourceMode
                    ? 'Categories are locked to Trending in Source Discovery Mode.'
                    : null,
                helperStyle: isSourceMode
                    ? TextStyle(color: Theme.of(context).colorScheme.tertiary)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items:
                  (isSourceMode
                          ? [TrackerCategory.trending]
                          : TrackerCategory.values)
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.label),
                        ),
                      )
                      .toList(),
              onChanged: isSourceMode
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                          _updateAutoTitle();
                        });
                      }
                    },
            ),
            const SizedBox(height: 16),
          ],

          if (_selectedType == HomeSectionType.libraryStatus) ...[
            DropdownButtonFormField<TrackedStatus>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'List to Display',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: TrackedStatus.values
                  .where((e) => e != TrackedStatus.unknown)
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.getLabelForMedia(_selectedMediaType)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedStatus = val;
                  _updateAutoTitle();
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TrackerType?>(
              initialValue: _targetTracker,
              decoration: InputDecoration(
                labelText: 'Data Source',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Auto (Default)'),
                ),
                ...TrackerType.values.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.displayName)),
                ),
              ],
              onChanged: (val) => setState(() => _targetTracker = val),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Section Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _titleController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _titleController.clear();
                        setState(() => _titleModified = true);
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() => _titleModified = true),
            onSubmitted: (_) => _save(),
          ),

          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _titleController.text.trim().isNotEmpty ? _save : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSectionSheet extends ConsumerStatefulWidget {
  final List<HomeSection> existingSections;

  const _AddSectionSheet({required this.existingSections});

  @override
  ConsumerState<_AddSectionSheet> createState() => _AddSectionSheetState();
}

class _AddSectionSheetState extends ConsumerState<_AddSectionSheet> {
  late final TextEditingController _titleController;
  HomeSectionType _selectedType = HomeSectionType.discovery;
  MediaType _selectedMediaType = MediaType.ANIME;
  TrackerCategory? _selectedCategory;
  TrackedStatus? _selectedStatus;
  TrackerType? _targetTracker;
  bool _titleModified = false;

  List<TrackerCategory> get _availableCategories {
    final isSourceMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode == MetadataMode.source),
    );

    if (isSourceMode) {
      final hasDiscoverySection = widget.existingSections.any(
        (s) =>
            s.type == HomeSectionType.discovery &&
            (s.targetMediaType ?? MediaType.ANIME) == _selectedMediaType,
      );
      if (hasDiscoverySection) return const [];
      return const [TrackerCategory.trending];
    }

    return TrackerCategory.values.where((cat) {
      return !widget.existingSections.any(
        (s) =>
            s.type == HomeSectionType.discovery &&
            (s.trackerCategory ?? TrackerCategory.trending) == cat &&
            (s.targetMediaType ?? MediaType.ANIME) == _selectedMediaType,
      );
    }).toList();
  }

  List<TrackedStatus> get _availableStatuses {
    return TrackedStatus.values.where((e) {
      if (e == TrackedStatus.unknown) return false;
      return !widget.existingSections.any(
        (s) =>
            s.type == HomeSectionType.libraryStatus &&
            s.libraryStatus == e &&
            (s.targetMediaType ?? MediaType.ANIME) == _selectedMediaType,
      );
    }).toList();
  }

  bool get _isContinueMediaAvailable {
    return !widget.existingSections.any(
      (s) =>
          s.type == HomeSectionType.continueMedia &&
          (s.targetMediaType ?? MediaType.ANIME) == _selectedMediaType,
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _updateFormState();
  }

  void _updateFormState() {
    if (_selectedType == HomeSectionType.discovery) {
      final availableCats = _availableCategories;
      if (availableCats.isNotEmpty) {
        if (_selectedCategory == null ||
            !availableCats.contains(_selectedCategory)) {
          _selectedCategory = availableCats.first;
        }
      } else {
        _selectedCategory = null;
      }
    } else if (_selectedType == HomeSectionType.libraryStatus) {
      final availableStats = _availableStatuses;
      if (availableStats.isNotEmpty) {
        if (_selectedStatus == null ||
            !availableStats.contains(_selectedStatus)) {
          _selectedStatus = availableStats.first;
        }
      } else {
        _selectedStatus = null;
      }
    }
    _updateAutoTitle();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _updateAutoTitle() {
    if (_titleModified) return;

    String newTitle = '';
    switch (_selectedType) {
      case HomeSectionType.discovery:
        final catLabel = _selectedCategory?.label ?? 'Discovery';
        newTitle = '$catLabel ${_selectedMediaType.displayName}';
        break;
      case HomeSectionType.continueMedia:
        newTitle = _selectedMediaType == MediaType.ANIME
            ? 'Continue Watching'
            : 'Continue Reading';
        break;
      case HomeSectionType.libraryStatus:
        newTitle = _selectedStatus != null
            ? 'My ${_selectedStatus!.displayName}'
            : '';
        break;
    }
    _titleController.text = newTitle;
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    ref
        .read(userHomeLayoutProvider.notifier)
        .addSection(
          HomeSection(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            type: _selectedType,
            targetMediaType: _selectedMediaType,
            trackerCategory: _selectedCategory,
            libraryStatus: _selectedStatus,
            targetTracker: _targetTracker,
          ),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSourceMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode == MetadataMode.source),
    );

    final isDiscovery = _selectedType == HomeSectionType.discovery;
    final isLibrary = _selectedType == HomeSectionType.libraryStatus;
    final isContinue = _selectedType == HomeSectionType.continueMedia;

    final availableCats = _availableCategories;
    final availableStats = _availableStatuses;
    final isContinueValid = _isContinueMediaAvailable;

    final bool canAdd =
        (isDiscovery && availableCats.isNotEmpty) ||
        (isLibrary && availableStats.isNotEmpty) ||
        (isContinue && isContinueValid);

    return AppBottomSheet(
      title: 'Add Section',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<HomeSectionType>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'Section Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: HomeSectionType.discovery,
                child: Text('Discovery Category'),
              ),
              DropdownMenuItem(
                value: HomeSectionType.continueMedia,
                child: Text('Continue Media'),
              ),
              DropdownMenuItem(
                value: HomeSectionType.libraryStatus,
                child: Text('Custom Library List'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedType = val;
                  _updateFormState();
                });
              }
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<MediaType>(
            initialValue: _selectedMediaType,
            decoration: InputDecoration(
              labelText: 'Media Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: MediaType.ANIME, child: Text('Anime')),
              DropdownMenuItem(value: MediaType.MANGA, child: Text('Manga')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedMediaType = val;
                  _updateFormState();
                });
              }
            },
          ),
          const SizedBox(height: 16),

          if (isDiscovery) ...[
            if (availableCats.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  isSourceMode
                      ? 'In Source Discovery Mode, only 1 discovery section per media type is supported.'
                      : 'All discovery categories for ${_selectedMediaType.displayName} are already on your home screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ] else ...[
              DropdownButtonFormField<TrackerCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  helperText: isSourceMode
                      ? 'Categories are locked to Trending in Source Discovery Mode.'
                      : null,
                  helperStyle: isSourceMode
                      ? TextStyle(color: Theme.of(context).colorScheme.tertiary)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: availableCats
                    .map(
                      (cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat.label)),
                    )
                    .toList(),
                onChanged: isSourceMode
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                            _updateAutoTitle();
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
            ],
          ] else if (isContinue) ...[
            if (!isContinueValid) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Continue ${_selectedMediaType.displayName} section is already on your home screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ] else if (isLibrary) ...[
            if (availableStats.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'All tracking lists for ${_selectedMediaType.displayName} are already on your home screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ] else ...[
              DropdownButtonFormField<TrackedStatus>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'List to Display',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: availableStats
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.getLabelForMedia(_selectedMediaType)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedStatus = val;
                    _updateAutoTitle();
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TrackerType?>(
                initialValue: _targetTracker,
                decoration: InputDecoration(
                  labelText: 'Data Source',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Auto (Default)'),
                  ),
                  ...TrackerType.values.map(
                    (t) =>
                        DropdownMenuItem(value: t, child: Text(t.displayName)),
                  ),
                ],
                onChanged: (val) => setState(() => _targetTracker = val),
              ),
              const SizedBox(height: 16),
            ],
          ],

          if (canAdd) ...[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Section Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _titleController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _titleController.clear();
                          setState(() => _titleModified = true);
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() => _titleModified = true),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _titleController.text.trim().isNotEmpty
                    ? _submit
                    : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Add Section',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
