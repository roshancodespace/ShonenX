import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class DiscoveryModeSheet extends ConsumerWidget {
  const DiscoveryModeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(discoveryPrefsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBottomSheet(
      title: 'Discovery Mode',
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
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: prefs.mode == MetadataMode.tracker
                ? const _TrackerConfig(key: ValueKey('tracker'))
                : _SourceConfig(
                    key: const ValueKey('source'),
                    activeSources: prefs.activeSources,
                  ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => context.pop(),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerConfig extends ConsumerWidget {
  const _TrackerConfig({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryTracker = ref.watch(primaryTrackerProvider);

    return SettingsSection(
      title: 'METADATA SOURCE',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SettingsActionTile(
            icon: primaryTracker.type == TrackerType.anilist
                ? Icons.analytics_outlined
                : Icons.list_alt,
            title: primaryTracker.type.displayName,
            subtitle: 'Trending, search & details from your primary tracker',
            tileColor: theme.colorScheme.surfaceContainerHighest,
            accentColor: theme.colorScheme.primary,
            trailing: Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
          child: Text(
            'Change your primary tracker in Settings → Tracking.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceConfig extends ConsumerWidget {
  final List<String> activeSources;

  const _SourceConfig({super.key, required this.activeSources});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final availableSources = ref.watch(availableAnimeSourcesProvider);

    return SettingsSection(
      title: 'ACTIVE SOURCES',
      subtitle: 'Select sources to show in your home feed and search.',
      children: [
        availableSources.when(
          data: (sources) {
            if (sources.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No sources available.\nInstall extensions to use Source Mode.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: sources.map((source) {
                final isActive = activeSources.contains(source.id);

                return _SourceTile(
                  source: source,
                  isActive: isActive,
                  onToggle: () {
                    ref
                        .read(discoveryPrefsProvider.notifier)
                        .toggleSource(source.id);
                  },
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text('Error loading sources: $e'),
          ),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final SourceInfo source;
  final bool isActive;
  final VoidCallback onToggle;

  const _SourceTile({
    required this.source,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 10, right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SettingsActionTile(
          icon: source.type == SourceType.inbuilt
              ? Icons.home_outlined
              : Icons.extension_outlined,
          title: source.name,
          subtitle: source.type == SourceType.inbuilt
              ? 'Built-in'
              : 'Extension',
          tileColor: isActive
              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerHighest,
          foregroundColor: isActive ? colorScheme.onSurface : null,
          accentColor: isActive
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          onTap: onToggle,
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isActive
                ? Icon(
                    Icons.check_circle,
                    key: const ValueKey('check'),
                    color: colorScheme.primary,
                    size: 22,
                  )
                : Icon(
                    Icons.circle_outlined,
                    key: const ValueKey('uncheck'),
                    color: colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}
