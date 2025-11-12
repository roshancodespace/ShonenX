import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
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
            icon: const Icon(Iconsax.arrow_left_2)),
        title: const Text('Experimental Features'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: ListView(
          children: [
            ToggleableSettingsItem(
              accent: colorScheme.primary,
              icon: Icon(experimentalSettings.useMangayomiExtensions
                  ? Icons.extension_outlined
                  : Icons.extension_off_outlined),
              title: 'Mangayomi extension',
              description: 'Enables the experimental extension support',
              value: experimentalSettings.useMangayomiExtensions,
              onChanged: (value) {
                experimentalNotifier.updateSettings(
                    (state) => state.copyWith(useMangayomiExtensions: value));
              },
            ),
            ToggleableSettingsItem(
              accent: colorScheme.primary,
              icon: Icon(Icons.replay_outlined),
              title: 'Episode Title Sync',
              description: 'Sync episode titles using JIKAN API',
              value: experimentalSettings.episodeTitleSync,
              onChanged: (value) {
                experimentalNotifier.updateSettings(
                    (state) => state.copyWith(episodeTitleSync: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}
