import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

void showAppearanceSheet(
  BuildContext context,
  WidgetRef ref,
  ThemePrefsNotifier themeNotifier,
  ThemePrefsState initialThemePrefs,
  ThemeData theme,
) {
  AppBottomSheet.show(
    context: context,
    title: 'Global UI Customization',
    child: Consumer(
      builder: (_, r, __) {
        final currentPrefs = r.watch(themePrefsProvider);
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlobalUiPreview(
                theme,
                currentPrefs.uiRoundness,
                currentPrefs.fontScaleFactor,
                currentPrefs.uiScaleFactor,
              ),
              SettingsSliderTile(
                title: 'Border Roundness',
                subtitle: 'Corner roundness across the app',
                value: currentPrefs.uiRoundness,
                min: 0.0,
                max: 32.0,
                divisions: 32,
                label: currentPrefs.uiRoundness.toStringAsFixed(1),
                icon: Icons.rounded_corner_outlined,
                onChanged: (v) => themeNotifier.updateTheme(
                  (s) => s.copyWith(uiRoundness: v),
                ),
              ),
              SettingsSliderTile(
                title: 'Font Scale',
                subtitle: 'Scale text size globally',
                value: currentPrefs.fontScaleFactor,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(currentPrefs.fontScaleFactor * 100).toInt()}%',
                icon: Icons.format_size_outlined,
                onChanged: (v) => themeNotifier.updateTheme(
                  (s) => s.copyWith(fontScaleFactor: v),
                ),
              ),
              SettingsSliderTile(
                title: 'Widget Scale',
                subtitle: 'Scale media cards & navigation bar',
                value: currentPrefs.uiScaleFactor,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(currentPrefs.uiScaleFactor * 100).toInt()}%',
                icon: Icons.aspect_ratio_outlined,
                onChanged: (v) => themeNotifier.updateTheme(
                  (s) => s.copyWith(uiScaleFactor: v),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildGlobalUiPreview(
  ThemeData theme,
  double roundness,
  double fontScale,
  double uiScale,
) {
  final cs = theme.colorScheme;
  return Container(
    height: 120,
    alignment: Alignment.center,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: AnimatedScale(
      scale: uiScale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Builder(
        builder: (context) {
          final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(currentTextScale / uiScale),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: 220,
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(roundness),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(roundness * 0.6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Primary text',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Secondary text',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
