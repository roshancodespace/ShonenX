import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/providers/locale_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class LanguageSelectionSheet extends ConsumerWidget {
  const LanguageSelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      title: context.l10n.settingsLanguage,
      titleIcon: Icons.translate_rounded,
      child: const LanguageSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(appLocaleProvider);
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          padding: EdgeInsets.zero,
          children: [
            SettingsSelectionTile(
              title: l10n.settingsSystemDefault,
              subtitle: 'Follow device system language',
              isSelected: activeLocale == null,
              onSelect: () {
                ref.read(appLocaleProvider.notifier).setLocale(null);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsGroup(
          padding: EdgeInsets.zero,
          children: kSupportedAppLanguages
              .map(
                (lang) => SettingsSelectionTile(
                  title: lang.nativeName,
                  subtitle: lang.englishName,
                  isSelected: activeLocale?.languageCode == lang.code,
                  onSelect: () {
                    ref.read(appLocaleProvider.notifier).setLocale(lang.locale);
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
