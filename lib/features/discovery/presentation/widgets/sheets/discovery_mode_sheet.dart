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
                  icon: Icon(Icons.cloud_outlined),
                ),
                ButtonSegment(
                  value: MetadataMode.source,
                  label: Text('Sources'),
                  icon: Icon(Icons.extension_outlined),
                ),
              ],
              selected: {prefs.mode},
              onSelectionChanged: (value) {
                ref.read(discoveryPrefsProvider.notifier).setMode(value.first);
              },
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              child: prefs.mode == MetadataMode.tracker
                  ? const _TrackerConfig(key: ValueKey('tracker'))
                  : _SourceConfig(
                      key: const ValueKey('source'),
                      activeSources: prefs.activeSources,
                    ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: context.pop, child: const Text('Done')),
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
        Text(
          'METADATA SOURCE',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the source for trending feeds, search results, and metadata.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<String?>(
          contentPadding: EdgeInsets.zero,
          value: null,
          groupValue: targetId,
          onChanged: (val) {
            ref.read(discoveryPrefsProvider.notifier).setMetadataTrackerId(val);
          },
          title: Text('Auto (${primaryTracker.type.displayName})'),
          subtitle: const Text('Matches your primary tracker'),
        ),
        for (final tracker in trackers)
          RadioListTile<String?>(
            contentPadding: EdgeInsets.zero,
            value: tracker.type.id,
            groupValue: targetId,
            onChanged: (val) {
              ref
                  .read(discoveryPrefsProvider.notifier)
                  .setMetadataTrackerId(val);
            },
            title: Text(tracker.type.displayName),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.tonalIcon(
          onPressed: () {
            context.pop();
            context.push('/settings/extensions');
          },
          icon: const Icon(Icons.extension_outlined),
          label: const Text('Manage Extensions'),
        ),
        const SizedBox(height: 18),
        Text(
          'ACTIVE SOURCES',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select sources for discovery and search.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
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
                      Text(
                        'ANIME SOURCES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final source in animeSources)
                        _SourceTile(
                          key: ValueKey('anime-${source.id}'),
                          source: source,
                          isActive: activeSources.contains(source.id),
                          onToggle: () {
                            ref
                                .read(discoveryPrefsProvider.notifier)
                                .toggleSource(source.id);
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                    if (mangaSources.isNotEmpty) ...[
                      Text(
                        'MANGA SOURCES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final source in mangaSources)
                        _SourceTile(
                          key: ValueKey('manga-${source.id}'),
                          source: source,
                          isActive: activeSources.contains(source.id),
                          onToggle: () {
                            ref
                                .read(discoveryPrefsProvider.notifier)
                                .toggleSource(source.id);
                          },
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
                child: Text('Failed to load sources\n$e'),
              ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            Icons.extension_off_outlined,
            size: 42,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 14),
          Text('No sources available', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Install extensions to use Source Mode.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              context.pop();
              context.push('/settings/extensions');
            },
            child: const Text('Browse Extensions'),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    super.key,
    required this.source,
    required this.isActive,
    required this.onToggle,
  });

  final SourceInfo source;
  final bool isActive;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onToggle,
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        child: Icon(
          source.type == SourceType.inbuilt
              ? Icons.home_outlined
              : Icons.extension_outlined,
          key: ValueKey(isActive),
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(source.name),
      subtitle: Text(
        source.type == SourceType.inbuilt
            ? 'Built-in source'
            : 'Extension source',
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          isActive
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          key: ValueKey(isActive),
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
