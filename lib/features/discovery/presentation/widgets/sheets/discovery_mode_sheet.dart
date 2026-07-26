import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class DiscoveryModeSheet extends ConsumerStatefulWidget {
  const DiscoveryModeSheet({super.key});

  @override
  ConsumerState<DiscoveryModeSheet> createState() => _DiscoveryModeSheetState();
}

class _DiscoveryModeSheetState extends ConsumerState<DiscoveryModeSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(discoveryPrefsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppBottomSheet(
      title: 'Discovery Mode',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSegmentedTile<MetadataMode>(
              padding: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: MetadataMode.tracker,
                  label: Text('Tracker'),
                  icon: Icon(Icons.cloud_rounded),
                ),
                ButtonSegment(
                  value: MetadataMode.source,
                  label: Text('Sources'),
                  icon: Icon(Icons.extension_rounded),
                ),
              ],
              selected: {prefs.mode},
              onSelectionChanged: (value) {
                ref.read(discoveryPrefsProvider.notifier).setMode(value.first);
              },
            ),
            const SizedBox(height: 20),

            if (prefs.mode == MetadataMode.source)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search sources...',
                    prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: prefs.mode == MetadataMode.tracker
                    ? const _TrackerConfig(key: ValueKey('tracker'))
                    : _SourceConfig(
                        key: const ValueKey('source'),
                        activeSources: prefs.activeSources,
                        searchQuery: _searchQuery,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.pop,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 1,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerConfig extends ConsumerWidget {
  const _TrackerConfig({super.key});

  Widget _buildTrackerRow({
    required BuildContext context,
    required String? value,
    required String? groupValue,
    required String title,
    required String subtitle,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelected = value == groupValue;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 28, height: 28, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 14,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? cs.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final prefs = ref.watch(discoveryPrefsProvider);
    final targetId = prefs.metadataTrackerId;

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackers = ref
        .watch(availableTrackersProvider)
        .whereType<RemoteTracker>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'METADATA TRACKER',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the source for trending feeds, search results, and metadata.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              _buildTrackerRow(
                context: context,
                value: null,
                groupValue: targetId,
                title: 'Auto (${primaryTracker.type.displayName})',
                subtitle: 'Matches your primary tracker',
                leading: Icon(
                  Icons.sync_rounded,
                  size: 24,
                  color: targetId == null ? cs.primary : cs.onSurfaceVariant,
                ),
                onTap: () => ref
                    .read(discoveryPrefsProvider.notifier)
                    .setMetadataTrackerId(null),
              ),
              if (trackers.isNotEmpty)
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
              ...trackers.asMap().entries.map((entry) {
                final idx = entry.key;
                final tracker = entry.value;
                final isLast = idx == trackers.length - 1;
                final isSelected = tracker.type.id == targetId;
                return Column(
                  children: [
                    _buildTrackerRow(
                      context: context,
                      value: tracker.type.id,
                      groupValue: targetId,
                      title: tracker.type.displayName,
                      subtitle: 'Use specific tracker metadata',
                      leading: tracker.type.getIconWidget(
                        size: 24,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      onTap: () => ref
                          .read(discoveryPrefsProvider.notifier)
                          .setMetadataTrackerId(tracker.type.id),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: cs.outline.withValues(alpha: 0.1),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceConfig extends ConsumerWidget {
  const _SourceConfig({
    super.key,
    required this.activeSources,
    this.searchQuery = '',
  });

  final List<String> activeSources;
  final String searchQuery;

  Widget _buildSourceRow({
    required BuildContext context,
    required SourceInfo source,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            source.iconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: source.iconUrl!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      source.type == SourceType.inbuilt
                          ? Icons.home_rounded
                          : Icons.code_rounded,
                      size: 16,
                      color: isActive ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                      color: isActive ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    source.type == SourceType.inbuilt
                        ? 'Built-in source'
                        : 'Extension',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? cs.primary : Colors.transparent,
                border: Border.all(
                  color: isActive ? cs.primary : cs.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: isActive
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceGroup({
    required BuildContext context,
    required List<SourceInfo> sources,
    required WidgetRef ref,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        children: sources.asMap().entries.map((entry) {
          final idx = entry.key;
          final source = entry.value;
          final isLast = idx == sources.length - 1;
          final isActive = activeSources.contains(source.id);

          return Column(
            children: [
              _buildSourceRow(
                context: context,
                source: source,
                isActive: isActive,
                onTap: () {
                  ref
                      .read(discoveryPrefsProvider.notifier)
                      .toggleSource(source.id);
                },
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: cs.outline.withValues(alpha: 0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            context.pop();
            context.push('/settings/extensions');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.extension_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage Extensions',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        ref
            .watch(allAvailableSourcesProvider)
            .when(
              data: (sources) {
                if (sources.isEmpty) {
                  return const _EmptySourcesState();
                }

                final filteredSources = sources
                    .where(
                      (s) =>
                          searchQuery.isEmpty ||
                          s.name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();

                final animeSources = filteredSources
                    .where((s) => s.mediaType == MediaType.ANIME)
                    .toList();
                final mangaSources = filteredSources
                    .where((s) => s.mediaType == MediaType.MANGA)
                    .toList();

                if (animeSources.isEmpty &&
                    mangaSources.isEmpty &&
                    searchQuery.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'No sources matching "$searchQuery"',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (animeSources.isNotEmpty) ...[
                      _CollapsibleSourceGroup(
                        title: 'ANIME SOURCES',
                        forceExpand: searchQuery.isNotEmpty,
                        activeCount: animeSources
                            .where((s) => activeSources.contains(s.id))
                            .length,
                        totalCount: animeSources.length,
                        child: _buildSourceGroup(
                          context: context,
                          sources: animeSources,
                          ref: ref,
                        ),
                      ),
                    ],
                    if (mangaSources.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _CollapsibleSourceGroup(
                        title: 'MANGA SOURCES',
                        forceExpand: searchQuery.isNotEmpty,
                        activeCount: mangaSources
                            .where((s) => activeSources.contains(s.id))
                            .length,
                        totalCount: mangaSources.length,
                        child: _buildSourceGroup(
                          context: context,
                          sources: mangaSources,
                          ref: ref,
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Failed to load sources\n$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.error),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _CollapsibleSourceGroup extends StatefulWidget {
  final String title;
  final Widget child;
  final bool forceExpand;
  final int activeCount;
  final int totalCount;

  const _CollapsibleSourceGroup({
    required this.title,
    required this.child,
    this.forceExpand = false,
    required this.activeCount,
    required this.totalCount,
  });

  @override
  State<_CollapsibleSourceGroup> createState() =>
      _CollapsibleSourceGroupState();
}

class _CollapsibleSourceGroupState extends State<_CollapsibleSourceGroup> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final expanded = widget.forceExpand || _isExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.activeCount}/${widget.totalCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: cs.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: widget.child,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _EmptySourcesState extends StatelessWidget {
  const _EmptySourcesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.extension_off_rounded, size: 48, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            'No sources available',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t installed any extensions yet. Head over to the extensions page to add some!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
