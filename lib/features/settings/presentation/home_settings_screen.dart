import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
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
    final isLibraryStatus =
        section.type == HomeSectionType.localLibraryStatus ||
        section.type == HomeSectionType.cloudLibraryStatus;

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
          // Delete Option (only for removable sections)
          if (isLibraryStatus)
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
  TrackerType? _targetTracker;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    _selectedType = widget.section.type;
    _targetTracker = widget.section.targetTracker;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
            targetTracker: _targetTracker,
            clearTargetTracker: _targetTracker == null,
          ),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLibraryStatus =
        widget.section.type == HomeSectionType.localLibraryStatus ||
        widget.section.type == HomeSectionType.cloudLibraryStatus;

    return AppBottomSheet(
      title: 'Edit Section',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                        setState(() {});
                      },
                    )
                  : null,
            ),
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
          if (isLibraryStatus) ...[
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
              onChanged: (val) {
                setState(() => _targetTracker = val);
              },
            ),
          ],
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
  TrackedStatus? _selectedStatus;
  TrackerType? _targetTracker;
  late final TextEditingController _titleController;
  late final List<TrackedStatus> _availableStatuses;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    _availableStatuses = TrackedStatus.values
        .where(
          (e) =>
              e != TrackedStatus.unknown &&
              !widget.existingSections.any((s) => s.libraryStatus == e),
        )
        .toList();

    if (_availableStatuses.isNotEmpty) {
      _selectedStatus = _availableStatuses.first;
      _titleController.text = 'My ${_selectedStatus!.displayName}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (_selectedStatus == null || title.isEmpty) return;

    ref
        .read(userHomeLayoutProvider.notifier)
        .addSection(
          HomeSection(
            id: _selectedStatus!.id,
            title: title,
            type: HomeSectionType
                .localLibraryStatus, // Type is legacy/internal, functionally dynamic
            libraryStatus: _selectedStatus!,
            targetTracker: _targetTracker,
          ),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isValid =
        _selectedStatus != null && _titleController.text.trim().isNotEmpty;

    return AppBottomSheet(
      title: 'Add Section',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_availableStatuses.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All tracking statuses are already on your home screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            DropdownButtonFormField<TrackedStatus>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'List to Display',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Consistent input borders
                ),
              ),
              items: _availableStatuses
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e, child: Text(e.displayName)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  if (_titleController.text.startsWith('My ') ||
                      _titleController.text.isEmpty) {
                    _titleController.text = 'My ${value?.displayName ?? ''}';
                  }
                });
              },
            ),
            const SizedBox(height: 16),

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
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
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
              onChanged: (val) {
                setState(() => _targetTracker = val);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: isValid ? () => _submit() : null,
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
