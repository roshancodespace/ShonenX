import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiPrefs = ref.watch(uiPrefsProvider);
    final uiPrefsNotifier = ref.read(uiPrefsProvider.notifier);

    return AppScaffold(
      title: 'UI',
      body: ListView(
        children: [
          SettingsActionTile(
            icon: Icons.view_compact,
            title: 'Card Style',
            subtitle: 'Change the style of the media cards',
            trailing: Text(uiPrefs.cardStyle.displayName),
            onTap: () {
              AppBottomSheet.show(
                context: context,
                title: 'Card Styles',
                child: Consumer(
                  builder: (context, ref, _) {
                    final uiPrefs = ref.watch(uiPrefsProvider);
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: uiPrefs.cardStyle.layout.width,
                            height: uiPrefs.cardStyle.layout.height,
                            child: MediaCard(
                              title: 'Demon Slayer: Kimetsu No Yaiba',
                              tag: '',
                              format: 'TV',
                              imageUrl:
                                  'https://m.media-amazon.com/images/M/MV5BM2IyN2E0NjctYWU2ZC00ZDc4LThiOTQtODAyOGNkZWM0M2E1XkEyXkFqcGc@._V1_.jpg',
                              onTap: () {},
                              style: uiPrefs.cardStyle,
                            ),
                          ),
                          ...MediaCardStyle.values.map(
                            (s) => ListTile(
                              leading: Icon(Icons.view_compact),
                              title: Text(s.displayName),
                              onTap: () {
                                uiPrefsNotifier.updateCardStyle(s);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          SettingsActionTile(
            icon: Icons.view_compact,
            title: 'Continue Watching Card Style',
            subtitle: 'Change the style of the continue watching cards',
            trailing: Text(uiPrefs.continueWatchingStyle.displayName),
            onTap: () {
              AppBottomSheet.show(
                context: context,
                title: 'Continue Watching Card Styles',
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ContinueWatchingStyle.values
                        .map(
                          (s) => ListTile(
                            leading: Icon(Icons.view_compact),
                            title: Text(s.displayName),
                            onTap: () {
                              uiPrefsNotifier.updateContinueWatchingStyle(s);
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
