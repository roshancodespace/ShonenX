import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/subtitle_prefs.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class SubtitleSettingsSheet extends ConsumerWidget {
  const SubtitleSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(subtitlePrefsProvider);
    final notifier = ref.read(subtitlePrefsProvider.notifier);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final responsiveFontSize = getResponsiveSubtitleSize(
      screenWidth,
      prefs.fontSize,
    );

    return AppBottomSheet(
      title: 'Subtitle Preferences',
      actions: [
        IconButton.filledTonal(
          tooltip: 'Reset to Defaults',
          style: IconButton.styleFrom(
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
          ),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () => notifier.updatePrefs(const SubtitlePrefs()),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                  'https://mir-s3-cdn-cf.behance.net/project_modules/1400_webp/833374164510463.63f7b82b9427d.png',
                ),
                fit: BoxFit.cover,
                alignment: Alignment(0, -0.5),
              ),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: getSubtitleTextStyle(
                prefs,
                responsiveFontSize.clamp(10.0, 100.0),
              ),
              textAlign: TextAlign.center,
              child: const Text(
                'Ore wa kaizoku ou ni naru!\n(I will become the Pirate King!)',
              ),
            ),
          ),

          Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                SettingsSwitchTile(
                  icon: Icons.subtitles_outlined,
                  title: 'Custom Overlay Engine',
                  subtitle: 'Overrides default player subtitles',
                  value: prefs.useCustomSubtitle,
                  onChanged: (value) {
                    notifier.updatePrefs(
                      prefs.copyWith(useCustomSubtitle: value),
                    );
                  },
                ),

                if (!prefs.useCustomSubtitle) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Native subtitles are active. Some appearance settings may not apply.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'APPEARANCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                SettingsDropdownTile<String>(
                  icon: Icons.font_download_outlined,
                  title: 'Font Family',
                  value: prefs.fontFamily,
                  items: kSubtitleFonts
                      .map(
                        (font) =>
                            DropdownMenuItem(value: font, child: Text(font)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      notifier.updatePrefs(prefs.copyWith(fontFamily: value));
                    }
                  },
                ),

                SettingsSliderTile(
                  icon: Icons.format_size_rounded,
                  title: 'Size Scale',
                  subtitle: 'Responsive based on screen width',
                  value: prefs.fontSize,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25, // Jumps by 0.1
                  label: '${prefs.fontSize.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    notifier.updatePrefs(prefs.copyWith(fontSize: value));
                  },
                ),

                SettingsActionTile(
                  icon: Icons.format_color_text_rounded,
                  title: 'Font Color',
                  trailing: _ColorIndicator(colorValue: prefs.fontColor),
                  onTap: () {
                    _showColorSheet(
                      context,
                      title: 'Font Color',
                      currentValue: prefs.fontColor,
                      options: const [
                        0xFFFFFFFF,
                        0xFFE0E0E0,
                        0xFFFFFF00,
                        0xFF00FFFF,
                        0xFF4CAF50,
                      ],
                      onChanged: (value) {
                        notifier.updatePrefs(prefs.copyWith(fontColor: value));
                      },
                    );
                  },
                ),

                SettingsActionTile(
                  icon: Icons.format_color_fill_rounded,
                  title: 'Background',
                  trailing: _ColorIndicator(colorValue: prefs.backgroundColor),
                  onTap: () {
                    _showColorSheet(
                      context,
                      title: 'Background',
                      currentValue: prefs.backgroundColor,
                      options: const [
                        0x00000000,
                        0x80000000,
                        0xFF000000,
                        0x80FFFFFF,
                      ],
                      onChanged: (value) {
                        notifier.updatePrefs(
                          prefs.copyWith(backgroundColor: value),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text(
                      'Advanced Settings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.format_bold_rounded,
                        title: 'Bold Text',
                        subtitle: 'Use thicker font weight',
                        value: prefs.bold,
                        onChanged: (value) {
                          notifier.updatePrefs(prefs.copyWith(bold: value));
                        },
                      ),
                      SettingsActionTile(
                        icon: Icons.border_style_rounded,
                        title: 'Outline Color',
                        trailing: _ColorIndicator(
                          colorValue: prefs.outlineColor,
                        ),
                        onTap: () {
                          _showColorSheet(
                            context,
                            title: 'Outline Color',
                            currentValue: prefs.outlineColor,
                            options: const [
                              0x00000000,
                              0x80000000,
                              0xFF000000,
                              0xFFFFFFFF,
                            ],
                            onChanged: (value) {
                              notifier.updatePrefs(
                                prefs.copyWith(outlineColor: value),
                              );
                            },
                          );
                        },
                      ),
                      SettingsSliderTile(
                        icon: Icons.line_weight_rounded,
                        title: 'Outline Size',
                        subtitle: 'Thickness of the stroke border',
                        value: prefs.outlineSize,
                        min: 0.0,
                        max: 5.0,
                        divisions: 10,
                        label: prefs.outlineSize.toStringAsFixed(1),
                        onChanged: (value) {
                          notifier.updatePrefs(
                            prefs.copyWith(outlineSize: value),
                          );
                        },
                      ),
                      SettingsActionTile(
                        icon: Icons.blur_on_rounded,
                        title: 'Drop Shadow Color',
                        trailing: _ColorIndicator(
                          colorValue: prefs.shadowColor,
                        ),
                        onTap: () {
                          _showColorSheet(
                            context,
                            title: 'Drop Shadow Color',
                            currentValue: prefs.shadowColor,
                            options: const [0x00000000, 0x80000000, 0xFF000000],
                            onChanged: (value) {
                              notifier.updatePrefs(
                                prefs.copyWith(shadowColor: value),
                              );
                            },
                          );
                        },
                      ),
                      SettingsSliderTile(
                        icon: Icons.blur_linear_rounded,
                        title: 'Drop Shadow Blur',
                        subtitle: 'Softness of drop shadow behind text',
                        value: prefs.shadowBlur,
                        min: 0.0,
                        max: 10.0,
                        divisions: 20,
                        label: prefs.shadowBlur.toStringAsFixed(1),
                        onChanged: (value) {
                          notifier.updatePrefs(
                            prefs.copyWith(shadowBlur: value),
                          );
                        },
                      ),
                      SettingsSliderTile(
                        icon: Icons.vertical_align_bottom_rounded,
                        title: 'Bottom Padding',
                        subtitle: 'Distance from bottom edge',
                        value: prefs.bottomPadding,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${prefs.bottomPadding.round()}px',
                        onChanged: (value) {
                          notifier.updatePrefs(
                            prefs.copyWith(bottomPadding: value),
                          );
                        },
                      ),
                      SettingsSliderTile(
                        icon: Icons.space_bar_rounded,
                        title: 'Letter Spacing',
                        subtitle: 'Space between character letters',
                        value: prefs.letterSpacing,
                        min: -2.0,
                        max: 5.0,
                        divisions: 14,
                        label: '${prefs.letterSpacing.toStringAsFixed(1)}px',
                        onChanged: (value) {
                          notifier.updatePrefs(
                            prefs.copyWith(letterSpacing: value),
                          );
                        },
                      ),
                      SettingsSliderTile(
                        icon: Icons.notes_rounded,
                        title: 'Word Spacing',
                        subtitle: 'Space between words',
                        value: prefs.wordSpacing,
                        min: -3.0,
                        max: 10.0,
                        divisions: 26,
                        label: '${prefs.wordSpacing.toStringAsFixed(1)}px',
                        onChanged: (value) {
                          notifier.updatePrefs(
                            prefs.copyWith(wordSpacing: value),
                          );
                        },
                      ),
                      SettingsSliderTile(
                        icon: Icons.format_line_spacing_rounded,
                        title: 'Line Height',
                        subtitle: 'Vertical gap between subtitle lines',
                        value: prefs.lineHeight,
                        min: 0.8,
                        max: 2.0,
                        divisions: 24,
                        label: '${prefs.lineHeight.toStringAsFixed(2)}x',
                        onChanged: (value) {
                          notifier.updatePrefs(
                            prefs.copyWith(lineHeight: value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorSheet(
    BuildContext context, {
    required String title,
    required int currentValue,
    required List<int> options,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textController = TextEditingController(
      text: currentValue.toRadixString(16).padLeft(8, '0').toUpperCase(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: options.map((colorValue) {
                      final selected = currentValue == colorValue;
                      final transparent = colorValue == 0x00000000;

                      return GestureDetector(
                        onTap: () {
                          onChanged(colorValue);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: transparent
                                ? cs.surfaceContainerHighest
                                : Color(colorValue),
                            border: transparent
                                ? Border.all(color: cs.outlineVariant, width: 1)
                                : null,
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: transparent
                                      ? cs.onSurface
                                      : Colors.white,
                                )
                              : transparent
                              ? Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'Custom Hex (AARRGGBB)',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_rounded),
                        onPressed: () {
                          final val = int.tryParse(
                            textController.text,
                            radix: 16,
                          );
                          if (val != null) {
                            onChanged(val);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      final val = int.tryParse(value, radix: 16);
                      if (val != null) {
                        onChanged(val);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorIndicator extends StatelessWidget {
  final int colorValue;

  const _ColorIndicator({required this.colorValue});

  @override
  Widget build(BuildContext context) {
    final transparent = colorValue == 0x00000000;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: transparent ? cs.surfaceContainerHighest : Color(colorValue),
        border: transparent
            ? Border.all(color: cs.outlineVariant, width: 1)
            : null,
      ),
      child: transparent
          ? Icon(Icons.close_rounded, size: 12, color: cs.onSurfaceVariant)
          : null,
    );
  }
}
