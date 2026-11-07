import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
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
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // System Default Option
        _LanguageTile(
          title: l10n.settingsSystemDefault,
          subtitle: 'Follow device system language',
          isSelected: activeLocale == null,
          onTap: () {
            ref.read(appLocaleProvider.notifier).setLocale(null);
            Navigator.of(context).pop();
          },
          colorScheme: cs,
        ),
        const Divider(height: 16),
        ...kSupportedAppLanguages.map(
          (lang) => _LanguageTile(
            title: lang.nativeName,
            subtitle: lang.englishName,
            isSelected: activeLocale?.languageCode == lang.code,
            onTap: () {
              ref.read(appLocaleProvider.notifier).setLocale(lang.locale);
              Navigator.of(context).pop();
            },
            colorScheme: cs,
          ),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}

