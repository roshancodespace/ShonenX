import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/player/domain/subtitle_prefs.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class SubtitleSettingsSheet extends ConsumerStatefulWidget {
  const SubtitleSettingsSheet({super.key});

  @override
  ConsumerState<SubtitleSettingsSheet> createState() =>
      _SubtitleSettingsSheetState();
}

class _SubtitleSettingsSheetState extends ConsumerState<SubtitleSettingsSheet> {
  bool _showLivePreview = true;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(subtitlePrefsProvider);
    final notifier = ref.read(subtitlePrefsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.responsiveOrNull ?? ResponsiveData.from(context);
    final screenWidth = r.width;
    final bool isWide = r.isLandscape && r.widthTier.isAtLeast_medium;
    final responsiveFontSize = getResponsiveSubtitleSize(
      screenWidth,
      prefs.fontSize,
    );

    if (isWide) {
      final double paneWidth = (screenWidth * 0.32).clamp(320.0, 380.0);
      final routeAnimation =
          ModalRoute.of(context)?.animation ??
          const AlwaysStoppedAnimation(1.0);
      final curve = CurvedAnimation(
        parent: routeAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(curve);

      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: _buildPreviewText(prefs, responsiveFontSize),
                ),
              ),
              SlideTransition(
                position: slide,
                child: Container(
                  width: paneWidth,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Subtitles',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _HeaderIconButton(
                                icon: Icons.refresh_rounded,
                                onTap: () =>
                                    notifier.updatePrefs(const SubtitlePrefs()),
                              ),
                              const SizedBox(width: 4),
                              _HeaderIconButton(
                                icon: Icons.close_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 16),
                            children: [
                              ..._buildBasicSettings(
                                prefs,
                                notifier,
                                theme,
                                cs,
                              ),
                              Theme(
                                data: theme.copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    'Advanced Settings',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                  children: _buildAdvancedSettings(
                                    prefs,
                                    notifier,
                                    theme,
                                    cs,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppBottomSheet(
      title: 'Subtitle Preferences',
      actions: [
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: _showLivePreview
                ? cs.primaryContainer
                : cs.surfaceContainerHighest,
            foregroundColor: _showLivePreview
                ? cs.onPrimaryContainer
                : cs.onSurfaceVariant,
          ),
          icon: Icon(
            _showLivePreview
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            size: 20,
          ),
          onPressed: () => setState(() => _showLivePreview = !_showLivePreview),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
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
          if (_showLivePreview) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    'https://i.pinimg.com/736x/90/64/ee/9064eed5aabcfc7a30e8af33d040b565.jpg',
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -0.5),
                ),
              ),
              alignment: Alignment.center,
              child: _buildPreviewText(prefs, responsiveFontSize),
            ),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
          ],
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ..._buildBasicSettings(prefs, notifier, theme, cs),
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Advanced Settings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    children: _buildAdvancedSettings(
                      prefs,
                      notifier,
                      theme,
                      cs,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewText(SubtitlePrefs prefs, double responsiveFontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: ['何も…… なかった。', ' Nothing... happened.']
          .map(
            (line) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: EdgeInsets.symmetric(
                horizontal: prefs.padding * 1.5,
                vertical: prefs.padding * 0.5,
              ),
              decoration: prefs.backgroundColor != 0x00000000
                  ? BoxDecoration(
                      color: Color(prefs.backgroundColor),
                      borderRadius: BorderRadius.circular(6.0),
                    )
                  : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (getSubtitleStrokeStyle(
                        prefs,
                        responsiveFontSize.clamp(10.0, 100.0),
                      ) !=
                      null)
                    Text(
                      line,
                      textAlign: TextAlign.center,
                      style: getSubtitleStrokeStyle(
                        prefs,
                        responsiveFontSize.clamp(10.0, 100.0),
                      ),
                    ),
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: getSubtitleTextStyle(
                      prefs,
                      responsiveFontSize.clamp(10.0, 100.0),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildBasicSettings(
    SubtitlePrefs prefs,
    SubtitlePrefsNotifier notifier,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return [
      SettingsSwitchTile(
        icon: Icons.subtitles_outlined,
        title: 'Custom Engine Overlay',
        value: prefs.useCustomSubtitle,
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(useCustomSubtitle: value));
        },
      ),
      if (!prefs.useCustomSubtitle)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Native subtitles active. Some appearance settings may be ignored.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.error,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      SettingsDropdownTile<String>(
        icon: Icons.font_download_outlined,
        title: 'Font Family',
        value: prefs.fontFamily,
        items: kSubtitleFonts
            .map((font) => DropdownMenuItem(value: font, child: Text(font)))
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
        value: prefs.fontSize,
        min: 0.5,
        max: 3.0,
        divisions: 25,
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
        title: 'Background Color',
        trailing: _ColorIndicator(colorValue: prefs.backgroundColor),
        onTap: () {
          _showColorSheet(
            context,
            title: 'Background Color',
            currentValue: prefs.backgroundColor,
            options: const [0x00000000, 0x80000000, 0xFF000000, 0x80FFFFFF],
            onChanged: (value) {
              notifier.updatePrefs(prefs.copyWith(backgroundColor: value));
            },
          );
        },
      ),
      SettingsSwitchTile(
        icon: Icons.format_bold_rounded,
        title: 'Bold Text',
        value: prefs.bold,
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(bold: value));
        },
      ),
      SettingsSliderTile(
        icon: Icons.format_line_spacing_rounded,
        title: 'Line Height',
        value: prefs.lineHeight,
        min: 0.8,
        max: 2.0,
        divisions: 24,
        label: '${prefs.lineHeight.toStringAsFixed(2)}x',
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(lineHeight: value));
        },
      ),
    ];
  }

  List<Widget> _buildAdvancedSettings(
    SubtitlePrefs prefs,
    SubtitlePrefsNotifier notifier,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return [
      SettingsActionTile(
        icon: Icons.border_style_rounded,
        title: 'Outline Color',
        trailing: _ColorIndicator(colorValue: prefs.outlineColor),
        onTap: () {
          _showColorSheet(
            context,
            title: 'Outline Color',
            currentValue: prefs.outlineColor,
            options: const [0x00000000, 0x80000000, 0xFF000000, 0xFFFFFFFF],
            onChanged: (value) {
              notifier.updatePrefs(prefs.copyWith(outlineColor: value));
            },
          );
        },
      ),
      SettingsSliderTile(
        icon: Icons.line_weight_rounded,
        title: 'Outline Size',
        value: prefs.outlineSize,
        min: 0.0,
        max: 5.0,
        divisions: 10,
        label: prefs.outlineSize.toStringAsFixed(1),
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(outlineSize: value));
        },
      ),
      SettingsActionTile(
        icon: Icons.blur_on_rounded,
        title: 'Shadow Color',
        trailing: _ColorIndicator(colorValue: prefs.shadowColor),
        onTap: () {
          _showColorSheet(
            context,
            title: 'Shadow Color',
            currentValue: prefs.shadowColor,
            options: const [0x00000000, 0x80000000, 0xFF000000],
            onChanged: (value) {
              notifier.updatePrefs(prefs.copyWith(shadowColor: value));
            },
          );
        },
      ),
      SettingsSliderTile(
        icon: Icons.blur_linear_rounded,
        title: 'Shadow Blur',
        value: prefs.shadowBlur,
        min: 0.0,
        max: 10.0,
        divisions: 20,
        label: prefs.shadowBlur.toStringAsFixed(1),
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(shadowBlur: value));
        },
      ),
      SettingsSliderTile(
        icon: Icons.vertical_align_bottom_rounded,
        title: 'Bottom Padding',
        value: prefs.bottomPadding,
        min: 0,
        max: 100,
        divisions: 20,
        label: '${prefs.bottomPadding.round()}px',
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(bottomPadding: value));
        },
      ),
      SettingsSliderTile(
        icon: Icons.padding_rounded,
        title: 'Background Padding',
        value: prefs.padding,
        min: 0,
        max: 30,
        divisions: 15,
        label: '${prefs.padding.round()}px',
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(padding: value));
        },
      ),
      SettingsSliderTile(
        icon: Icons.space_bar_rounded,
        title: 'Letter Spacing',
        value: prefs.letterSpacing,
        min: -2.0,
        max: 5.0,
        divisions: 14,
        label: '${prefs.letterSpacing.toStringAsFixed(1)}px',
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(letterSpacing: value));
        },
      ),
      SettingsSliderTile(
        icon: Icons.notes_rounded,
        title: 'Word Spacing',
        value: prefs.wordSpacing,
        min: -3.0,
        max: 10.0,
        divisions: 26,
        label: '${prefs.wordSpacing.toStringAsFixed(1)}px',
        onChanged: (value) {
          notifier.updatePrefs(prefs.copyWith(wordSpacing: value));
        },
      ),
    ];
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
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
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
                          width: 44,
                          height: 44,
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
                      labelText: 'Hex Code (AARRGGBB)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: cs.onSurfaceVariant, size: 20),
      ),
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
      width: 20,
      height: 20,
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
