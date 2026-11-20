import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/utils/wallpaper_processor.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/settings/presentation/widgets/wallpaper_color_schemes_selector.dart';
import 'package:shonenx/features/settings/presentation/widgets/wallpaper_customization_sheet.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

class ThemeWallpaperTab extends ConsumerWidget {
  const ThemeWallpaperTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final notifier = ref.read(themePrefsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.only(bottom: 50),
      children: [
        // Wallpaper
        SettingsSection(
          title: 'Wallpaper',
          children: [
            SettingsActionTile(
              icon: Icons.image_outlined,
              title: 'Custom Wallpaper',
              subtitle: themePrefs.useAmoled
                  ? 'Disabled with Pure Black'
                  : themePrefs.customBackgroundImagePath != null
                  ? 'Change custom background image'
                  : 'Select a custom background image',
              onTap: themePrefs.useAmoled
                  ? null
                  : () async {
                      final result = await FilePicker.platform
                          .pickFiles(type: FileType.image);
                      if (result != null && result.files.single.path != null) {
                        final selectedPath = result.files.single.path!;

                        final safeOriginalPath =
                            await WallpaperProcessor.saveOriginalWallpaper(
                              selectedPath,
                            );

                        if (context.mounted) {
                          showWallpaperCustomizationSheet(
                            context,
                            imagePath: safeOriginalPath,
                            initialBlur: 0.0,
                            initialOpacity: 0.4,
                            initialSaturation: 1.0,
                            initialBrightness: 1.0,
                            isNewWallpaper: true,
                          );
                        }
                      }
                    },
            ),
            if (themePrefs.customBackgroundImagePath != null &&
                !themePrefs.useAmoled &&
                !themePrefs.customBackgroundImagePath!.startsWith(
                  'http',
                )) ...[
              SettingsActionTile(
                icon: Icons.tune_rounded,
                title: 'Customize Wallpaper',
                subtitle:
                    'Adjust blur, opacity, saturation, and brightness',
                onTap: () {
                  final ws = themePrefs.wallpaperSettings;
                  if (context.mounted &&
                      themePrefs.customBackgroundImagePath != null) {
                    showWallpaperCustomizationSheet(
                      context,
                      imagePath: themePrefs.customBackgroundImagePath!,
                      initialBlur: ws?.blur ?? 0.0,
                      initialOpacity: ws?.opacity ?? 0.4,
                      initialSaturation: ws?.saturation ?? 1.0,
                      initialBrightness: ws?.brightness ?? 1.0,
                      isNewWallpaper: false,
                    );
                  }
                },
              ),
              SettingsSwitchTile(
                icon: Icons.color_lens_outlined,
                title: 'Use Wallpaper Colors',
                subtitle: 'Generate theme colors from the wallpaper',
                value: themePrefs.useImageColors,
                onChanged: (v) => notifier.updateTheme(
                  (p) => p.copyWith(useImageColors: v),
                ),
              ),
              if (themePrefs.useImageColors &&
                  themePrefs.customBackgroundImagePath != null) ...[
                WallpaperColorSchemesSelector(
                  imagePath: themePrefs.customBackgroundImagePath!,
                  currentSeed:
                      themePrefs.wallpaperSettings?.imageColorSeed,
                  isDark: isDark,
                  onSelect: (seedArgb) {
                    notifier.updateTheme(
                      (p) => p.copyWith(
                        wallpaperSettings:
                            (p.wallpaperSettings ??
                                    WallpaperSettings(
                                      imagePath: themePrefs
                                          .customBackgroundImagePath!,
                                    ))
                                .copyWith(imageColorSeed: seedArgb),
                        useImageColors: true,
                      ),
                    );
                  },
                ),
              ],
              SettingsActionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Remove Wallpaper',
                subtitle: 'Clear custom background image',
                isDestructive: true,
                onTap: () async {
                  WallpaperProcessor.clearCache();
                  notifier.updateTheme(
                    (p) => p.copyWith(
                      clearWallpaperSettings: true,
                      useImageColors: false,
                    ),
                  );
                  final docDir =
                      await getApplicationDocumentsDirectory();
                  final dir = Directory(docDir.path);
                  try {
                    final files = dir.listSync();
                    for (final file in files) {
                      if (file is File &&
                          (file.path.contains('blurred_wallpaper_') ||
                              file.path.contains(
                                'original_wallpaper.png',
                              ))) {
                        await file.delete();
                      }
                    }
                  } catch (_) {}
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
