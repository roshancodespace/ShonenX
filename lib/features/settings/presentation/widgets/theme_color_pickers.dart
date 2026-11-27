import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/core/theme/standard_schemes.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_palette_showcase.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_variant_swatch_preview.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/selection_card_group.dart';

void showStandardSchemePicker(
  BuildContext context,
  AppScheme currentScheme,
  void Function(AppScheme) onSchemeSelected,
  bool isDark,
) {
  AppBottomSheet.show(
    context: context,
    title: context.l10n.settingsStandardSchemes,
    child: _SchemePicker(
      currentScheme: currentScheme,
      isDark: isDark,
      onSelected: (scheme) {
        onSchemeSelected(scheme);
        Navigator.pop(context);
      },
    ),
  );
}

void showExclusiveSchemePicker(
  BuildContext context,
  String? currentKey,
  void Function(String) onSelected,
  bool isDark,
) {
  AppBottomSheet.show(
    context: context,
    title: context.l10n.settingsExclusiveSchemes,
    child: _ExclusiveSchemePicker(
      currentKey: currentKey,
      isDark: isDark,
      onSelected: (key) {
        onSelected(key);
        Navigator.pop(context);
      },
    ),
  );
}

void showThemeVariantPicker(
  BuildContext context,
  AppThemeVariant currentVariant,
  void Function(AppThemeVariant) onSelected,
  bool isDark,
) {
  AppBottomSheet.show(
    context: context,
    title: context.l10n.settingsThemeStyle,
    child: _ThemeVariantPicker(
      currentVariant: currentVariant,
      isDark: isDark,
      onSelected: (variant) {
        onSelected(variant);
        Navigator.pop(context);
      },
    ),
  );
}

class _SchemePicker extends ConsumerWidget {
  const _SchemePicker({
    required this.currentScheme,
    required this.isDark,
    required this.onSelected,
  });

  final AppScheme currentScheme;
  final bool isDark;
  final void Function(AppScheme) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = standardSchemes.entries
        .where((e) => e.key != AppScheme.custom)
        .map(
          (e) => ThemePaletteItem.fromAppScheme(
            scheme: e.key,
            data: e.value,
            isDark: isDark,
          ),
        )
        .toList();

    return _SchemeGridPicker(
      items: items,
      selectedId: currentScheme.name,
      onSelected: (item) => onSelected(AppScheme.values.byName(item.id)),
    );
  }
}

class _ExclusiveSchemePicker extends ConsumerWidget {
  const _ExclusiveSchemePicker({
    required this.currentKey,
    required this.isDark,
    required this.onSelected,
  });

  final String? currentKey;
  final bool isDark;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = exclusiveSchemes.entries
        .map(
          (e) => ThemePaletteItem.fromExclusive(
            key: e.key,
            data: e.value,
            isDark: isDark,
          ),
        )
        .toList();

    return _SchemeGridPicker(
      items: items,
      selectedId: currentKey,
      onSelected: (item) => onSelected(item.id),
    );
  }
}

class _SchemeGridPicker extends StatelessWidget {
  const _SchemeGridPicker({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ThemePaletteItem> items;
  final String? selectedId;
  final ValueChanged<ThemePaletteItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 102,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ThemePaletteCard(
          item: item,
          isSelected: selectedId == item.id,
          onTap: () => onSelected(item),
          width: double.infinity,
          height: 102,
        );
      },
    );
  }
}

class _ThemeVariantPicker extends ConsumerWidget {
  const _ThemeVariantPicker({
    required this.currentVariant,
    required this.isDark,
    required this.onSelected,
  });

  final AppThemeVariant currentVariant;
  final bool isDark;
  final void Function(AppThemeVariant) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SelectionCardGroup(
        children: AppThemeVariant.values.map((variant) {
          final isSelected = currentVariant == variant;
          return SelectionCardTile(
            leading: ThemeVariantSwatchPreview(
              variant: variant,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            title: variant.displayName,
            subtitle: variant.subtitle,
            isSelected: isSelected,
            onTap: () => onSelected(variant),
          );
        }).toList(),
      ),
    );
  }
}
