import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/shared/providers/settings/experimental_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';

class ExperimentalScreen extends ConsumerWidget {
  const ExperimentalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experimentalSettings = ref.watch(experimentalProvider);
    final experimentalNotifier = ref.read(experimentalProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Experimental Features'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: ListView(
          children: [
            ToggleableSettingsItem(
              accent: colorScheme.primary,
              icon: Icon(
                experimentalSettings.useExtensions
                    ? Icons.extension_outlined
                    : Icons.extension_off_outlined,
              ),
              title: 'Extension',
              description: 'Enables the experimental extension support',
              value: experimentalSettings.useExtensions,
              onChanged: (value) {
                experimentalNotifier.updateSettings(
                  (state) => state.copyWith(useExtensions: value),
                );
              },
            ),
            const SizedBox(height: 8),
            ToggleableSettingsItem(
              accent: colorScheme.primary,
              icon: Icon(Icons.replay_outlined),
              title: 'Episode Title Sync',
              description: 'Sync episode titles using JIKAN API',
              value: experimentalSettings.episodeTitleSync,
              onChanged: (value) {
                experimentalNotifier.updateSettings(
                  (state) => state.copyWith(episodeTitleSync: value),
                );
              },
            ),
            const SizedBox(height: 8),
            ToggleableSettingsItem(
              accent: colorScheme.primary,
              icon: Icon(Iconsax.flash_15),
              title: 'Test Releases',
              description: 'Receive unstable test updates',
              value: experimentalSettings.useTestReleases,
              onChanged: (value) {
                experimentalNotifier.updateSettings(
                  (state) => state.copyWith(useTestReleases: value),
                );
              },
            ),
            const SizedBox(height: 8),
            ToggleableSettingsItem(
              accent: colorScheme.primary,
              icon: Icon(Icons.upcoming_rounded),
              title: 'New UI (ALPHA)',
              description: 'Trying to cook a better UI',
              value: experimentalSettings.newUI,
              onChanged: (value) {
                experimentalNotifier.updateSettings(
                  (state) => state.copyWith(newUI: value),
                );
              },
            ),
            const SizedBox(height: 8),
            ToggleableSettingsItem(
              accent: colorScheme.primary,
              icon: Icon(Icons.bug_report_outlined),
              title: 'Debug Mode',
              description: 'Enable debug mode',
              value: experimentalSettings.debugMode,
              onChanged: (value) {
                experimentalNotifier.updateSettings(
                  (state) => state.copyWith(debugMode: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
