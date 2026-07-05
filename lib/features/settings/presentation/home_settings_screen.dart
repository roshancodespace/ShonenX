import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class HomeSettingsScreen extends ConsumerWidget {
  const HomeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeSections = ref.watch(userHomeLayoutProvider);

    return AppScaffold(
      title: 'Home Settings',
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: homeSections.length,
        onReorder: (oldIndex, newIndex) {
          ref.read(userHomeLayoutProvider.notifier).reorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final section = homeSections[index];
          return ListTile(
            key: ValueKey(section.id),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            title: Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Type: ${section.type.name}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            leading: ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  Icons.drag_indicator,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: !section.disabled,
                  onChanged: (value) => ref
                      .read(userHomeLayoutProvider.notifier)
                      .updateSection(section.copyWith(disabled: !value)),
                ),
                // Menu button replacing the delete button
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      builder: (_) => _SectionOptionsSheet(section: section),
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Section Options',
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: () {
            ref.read(userHomeLayoutProvider.notifier).reset();
          },
          icon: const Icon(Icons.restore),
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
          icon: const Icon(Icons.add),
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
    final colorScheme = Theme.of(context).colorScheme;

    return AppBottomSheet(
      title: 'Section Options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Edit Option
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              context.pop(); // Close options sheet
              // Open edit sheet
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (_) => _EditSectionSheet(section: section),
              );
            },
          ),
          // Delete Option
          ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text('Delete', style: TextStyle(color: colorScheme.error)),
            onTap: () {
              context.pop(); // Close options sheet
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
  TrackedStatus? _selectedStatus;
  TrackerType? _targetTracker;
  bool _titleModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    _selectedType = widget.section.type;
    _selectedMediaType = widget.section.targetMediaType ?? MediaType.ANIME;
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
      case HomeSectionType.trending:
        newTitle = 'Trending ${_selectedMediaType.displayName}';
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
    if (_selectedType == HomeSectionType.libraryStatus &&
        _selectedStatus == null)
      return;

    ref
        .read(userHomeLayoutProvider.notifier)
        .updateSection(
          widget.section.copyWith(
            title: title,
            type: _selectedType,
            targetMediaType: _selectedMediaType,
            libraryStatus: _selectedStatus,
            targetTracker: _targetTracker,
            clearTargetTracker: _targetTracker == null,
          ),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Edit Section',
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
                value: HomeSectionType.trending,
                child: Text('Trending'),
              ),
              DropdownMenuItem(
                value: HomeSectionType.continueMedia,
                child: Text('Continue Media'),
              ),
              DropdownMenuItem(
                value: HomeSectionType.libraryStatus,
                child: Text('Library List'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedType = val;
                  if (val == HomeSectionType.libraryStatus &&
                      _selectedStatus == null) {
                    _selectedStatus = TrackedStatus.watching;
                  }
                  _updateAutoTitle();
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
                  _updateAutoTitle();
                });
              }
            },
          ),
          const SizedBox(height: 16),

          if (_selectedType == HomeSectionType.libraryStatus) ...[
            DropdownButtonFormField<TrackedStatus>(
              value: _selectedStatus,
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
              value: _targetTracker,
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

          const SizedBox(height: 32),
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
  HomeSectionType _selectedType = HomeSectionType.trending;
  MediaType _selectedMediaType = MediaType.ANIME;
  TrackedStatus? _selectedStatus;
  TrackerType? _targetTracker;
  bool _titleModified = false;

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

  bool get _isDuplicate {
    if (_selectedType == HomeSectionType.libraryStatus) return false;
    return widget.existingSections.any(
      (s) =>
          s.type == _selectedType &&
          (s.targetMediaType ?? MediaType.ANIME) == _selectedMediaType,
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _updateAvailableStatuses();
  }

  void _updateAvailableStatuses() {
    final available = _availableStatuses;
    if (available.isNotEmpty) {
      if (_selectedStatus == null || !available.contains(_selectedStatus)) {
        _selectedStatus = available.first;
      }
    } else {
      _selectedStatus = null;
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
      case HomeSectionType.trending:
        newTitle = 'Trending ${_selectedMediaType.displayName}';
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
    if (_selectedType == HomeSectionType.libraryStatus &&
        _selectedStatus == null)
      return;
    if (_isDuplicate) return;

    ref
        .read(userHomeLayoutProvider.notifier)
        .addSection(
          HomeSection(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            type: _selectedType,
            targetMediaType: _selectedMediaType,
            libraryStatus: _selectedStatus,
            targetTracker: _targetTracker,
          ),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLibraryType = _selectedType == HomeSectionType.libraryStatus;
    final available = _availableStatuses;
    final isDuplicate = _isDuplicate;
    final isValid =
        !isDuplicate &&
        _titleController.text.trim().isNotEmpty &&
        (!isLibraryType || _selectedStatus != null);

    return AppBottomSheet(
      title: 'Add Section',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<HomeSectionType>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Section Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: HomeSectionType.trending,
                child: Text('Trending'),
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
                  _updateAutoTitle();
                });
              }
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<MediaType>(
            value: _selectedMediaType,
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
                  if (_selectedType == HomeSectionType.libraryStatus) {
                    _updateAvailableStatuses();
                  } else {
                    _updateAutoTitle();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),

          if (isDuplicate) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'A section of this type and media already exists on your home screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ] else if (isLibraryType && available.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'All tracking lists for ${_selectedMediaType.displayName} are already on your home screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ] else ...[
            if (isLibraryType) ...[
              DropdownButtonFormField<TrackedStatus>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'List to Display',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: available
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
                value: _targetTracker,
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
                onPressed: isValid ? _submit : null,
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
