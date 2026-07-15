import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class DiscoveryModeSheet extends ConsumerWidget {
  const DiscoveryModeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(discoveryPrefsProvider);

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
            const SizedBox(height: 24),

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
                      ),
              ),
            ),

            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.pop,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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

        // Grouped Card Layout
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            child: Column(
              children: [
                RadioListTile<String?>(
                  value: null,
                  groupValue: targetId,
                  activeColor: cs.primary,
                  onChanged: (val) => ref
                      .read(discoveryPrefsProvider.notifier)
                      .setMetadataTrackerId(val),
                  title: Text(
                    'Auto (${primaryTracker.type.displayName})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Matches your primary tracker',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                if (trackers.isNotEmpty)
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ...trackers.map((tracker) {
                  final isLast = tracker == trackers.last;
                  return Column(
                    children: [
                      RadioListTile<String?>(
                        value: tracker.type.id,
                        groupValue: targetId,
                        activeColor: cs.primary,
                        onChanged: (val) => ref
                            .read(discoveryPrefsProvider.notifier)
                            .setMetadataTrackerId(val),
                        title: Text(
                          tracker.type.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceConfig extends ConsumerWidget {
  const _SourceConfig({super.key, required this.activeSources});

  final List<String> activeSources;

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
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.extension_rounded,
                    color: cs.onSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Extensions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        'Install or update content sources',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSecondaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        ref
            .watch(allAvailableSourcesProvider)
            .when(
              data: (sources) {
                if (sources.isEmpty) {
                  return const _EmptySourcesState();
                }

                final animeSources = sources
                    .where((s) => s.mediaType == MediaType.ANIME)
                    .toList();
                final mangaSources = sources
                    .where((s) => s.mediaType == MediaType.MANGA)
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (animeSources.isNotEmpty) ...[
                      _buildSectionHeader(context, 'ANIME SOURCES'),
                      _buildSourceGroup(
                        context: context,
                        ref: ref,
                        sources: animeSources,
                      ),
                    ],
                    if (mangaSources.isNotEmpty) ...[
                      _buildSectionHeader(context, 'MANGA SOURCES'),
                      _buildSourceGroup(
                        context: context,
                        ref: ref,
                        sources: mangaSources,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSourceGroup({
    required BuildContext context,
    required WidgetRef ref,
    required List<SourceInfo> sources,
  }) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        child: Column(
          children: sources.map((source) {
            final isLast = source == sources.last;
            final isActive = activeSources.contains(source.id);

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  onTap: () {
                    ref
                        .read(discoveryPrefsProvider.notifier)
                        .toggleSource(source.id);
                  },
                  leading: source.iconUrl != null
                      ? CachedNetworkImage(imageUrl: source.iconUrl!, width: 35)
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            source.type == SourceType.inbuilt
                                ? Icons.home_rounded
                                : Icons.code_rounded,
                            size: 20,
                            color: isActive ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                  title: Text(
                    source.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    source.type == SourceType.inbuilt
                        ? 'Built-in source'
                        : 'Extension',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  trailing: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? cs.primary : Colors.transparent,
                      border: Border.all(
                        color: isActive ? cs.primary : cs.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: isActive
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: cs.onPrimary,
                          )
                        : null,
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
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
