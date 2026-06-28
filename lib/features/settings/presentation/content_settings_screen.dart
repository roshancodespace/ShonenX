import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ContentSettingsScreen extends ConsumerWidget {
  const ContentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(contentPrefsProvider);

    return AppScaffold(
      title: 'Content Settings',
      body: ListView(
        children: [
          SettingsSection(
            title: 'Filters',
            children: [
              SettingsSegmentedTile<AdultContentMode>(
                title: 'Show 18+ Content',
                segments: const [
                  ButtonSegment(
                    value: AdultContentMode.safe,
                    label: Text('Safe'),
                  ),
                  ButtonSegment(
                    value: AdultContentMode.mixed,
                    label: Text('Mixed'),
                  ),
                  ButtonSegment(
                    value: AdultContentMode.adultOnly,
                    label: Text('18+ Only'),
                  ),
                ],
                selected: {prefs.adultContentMode},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setAdultContentMode(set.first);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
