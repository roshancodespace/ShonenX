import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
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
  static const _previewImageUrl =
      'https://i.pinimg.com/736x/90/64/ee/9064eed5aabcfc7a30e8af33d040b565.jpg';

  bool _showLivePreview = true;
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(subtitlePrefsProvider);
    final notifier = ref.read(subtitlePrefsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.responsiveOrNull ?? ResponsiveData.from(context);
    final isWide = r.isLandscape && r.widthTier.isAtLeast_medium;
    final responsiveFontSize = getResponsiveSubtitleSize(
      r.width,
      prefs.fontSize,
    );

    if (isWide) {
      final paneWidth = (r.width * 0.36).clamp(360.0, 440.0);
      final routeAnimation =
          ModalRoute.of(context)?.animation ??
          const AlwaysStoppedAnimation(1.0);
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: routeAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _buildPreviewCard(
                          prefs,
                          responsiveFontSize,
                          radius: 22,
                          verticalPadding: 24,
                          bottomAligned: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: slide,
                child: Container(
                  width: paneWidth,
                  margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  child: Material(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.playerSubtitlePreferences,
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
                        _buildTabStrip(cs),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 20),
                            children: _buildActiveTabContent(
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppBottomSheet(
      title: context.l10n.playerSubtitlePreferences,
      contentPadding: EdgeInsets.zero,
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
          if (_showLivePreview)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _buildPreviewCard(
                prefs,
                responsiveFontSize,
                radius: 18,
                verticalPadding: 24,
              ),
            ),
          _buildTabStrip(cs),
          const SizedBox(height: 6),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              children: _buildActiveTabContent(prefs, notifier, theme, cs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabStrip(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final entry in const [
                (0, 'Style'),
                (1, 'Effects'),
                (2, 'Layout'),
              ])
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tabIndex = entry.$1),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _tabIndex == entry.$1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _tabIndex == entry.$1
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            height: 2.5,
                            width: _tabIndex == entry.$1 ? 28 : 0,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(999),
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
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _buildPreviewCard(
    SubtitlePrefs prefs,
    double responsiveFontSize, {
    required double radius,
    required double verticalPadding,
    bool bottomAligned = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: SmartImage(
              imageUrl: _previewImageUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.45),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: 20,
            ),
            alignment: bottomAligned
                ? Alignment.bottomCenter
                : Alignment.center,
            child: _buildPreviewText(prefs, responsiveFontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewText(SubtitlePrefs prefs, double responsiveFontSize) {
    final fontSize = responsiveFontSize.clamp(10.0, 100.0);
    final strokeStyle = getSubtitleStrokeStyle(prefs, fontSize);
    final textStyle = getSubtitleTextStyle(prefs, fontSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: ['何も…… なかった。', 'Nothing... happened.']
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
                  if (strokeStyle != null)
                    Text(line, textAlign: TextAlign.center, style: strokeStyle),
                  Text(line, textAlign: TextAlign.center, style: textStyle),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildActiveTabContent(
    SubtitlePrefs prefs,
    SubtitlePrefsNotifier notifier,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return switch (_tabIndex) {
      0 => _buildStyleTab(prefs, notifier, theme, cs),
      1 => _buildEffectsTab(prefs, notifier),
      _ => _buildLayoutTab(prefs, notifier),
    };
  }

  List<Widget> _buildStyleTab(
    SubtitlePrefs prefs,
    SubtitlePrefsNotifier notifier,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final l10n = context.l10n;
    return [
      SettingsSection(
        title: 'Typography',
        children: [
          SettingsSwitchTile(
            icon: Icons.subtitles_outlined,
            title: l10n.subtitleCustomEngineOverlay,
            value: prefs.useCustomSubtitle,
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(useCustomSubtitle: value)),
          ),
          if (!prefs.useCustomSubtitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.subtitleNativeActiveWarning,
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
            title: l10n.subtitleFontFamily,
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
            title: l10n.subtitleSizeScale,
            value: prefs.fontSize,
            min: 0.5,
            max: 3.0,
            divisions: 25,
            label: '${prefs.fontSize.toStringAsFixed(1)}x',
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(fontSize: value)),
          ),
          SettingsSwitchTile(
            icon: Icons.format_bold_rounded,
            title: l10n.subtitleBoldText,
            value: prefs.bold,
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(bold: value)),
          ),
        ],
      ),
      SettingsSection(
        title: 'Colors',
        children: [
          _ColorStudioTile(
            overline: 'TEXT',
            title: l10n.subtitleFontColor,
            currentValue: prefs.fontColor,
            options: const [
              0xFFFFFFFF,
              0xFFE0E0E0,
              0xFFFFEB3B,
              0xFF00E5FF,
              0xFF69F0AE,
            ],
            onChanged: (v) => notifier.updatePrefs(prefs.copyWith(fontColor: v)),
          ),
          _ColorStudioTile(
            overline: 'BACKDROP',
            title: l10n.readerBackgroundColor,
            currentValue: prefs.backgroundColor,
            options: const [0x00000000, 0x80000000, 0xCC000000, 0x80FFFFFF],
            onChanged: (v) =>
                notifier.updatePrefs(prefs.copyWith(backgroundColor: v)),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildEffectsTab(
    SubtitlePrefs prefs,
    SubtitlePrefsNotifier notifier,
  ) {
    final l10n = context.l10n;
    return [
      SettingsSection(
        title: 'Outline',
        children: [
          _ColorStudioTile(
            overline: 'STROKE',
            title: l10n.subtitleOutlineColor,
            currentValue: prefs.outlineColor,
            options: const [0x00000000, 0x80000000, 0xFF000000, 0xFFFFFFFF],
            onChanged: (v) =>
                notifier.updatePrefs(prefs.copyWith(outlineColor: v)),
          ),
          SettingsSliderTile(
            icon: Icons.line_weight_rounded,
            title: l10n.subtitleOutlineSize,
            value: prefs.outlineSize,
            min: 0.0,
            max: 5.0,
            divisions: 10,
            label: prefs.outlineSize.toStringAsFixed(1),
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(outlineSize: value)),
          ),
        ],
      ),
      SettingsSection(
        title: 'Shadow',
        children: [
          _ColorStudioTile(
            overline: 'DROP SHADOW',
            title: l10n.subtitleShadowColor,
            currentValue: prefs.shadowColor,
            options: const [0x00000000, 0x80000000, 0xB3000000, 0xFF000000],
            onChanged: (v) =>
                notifier.updatePrefs(prefs.copyWith(shadowColor: v)),
          ),
          SettingsSliderTile(
            icon: Icons.blur_linear_rounded,
            title: l10n.subtitleShadowBlur,
            value: prefs.shadowBlur,
            min: 0.0,
            max: 10.0,
            divisions: 20,
            label: prefs.shadowBlur.toStringAsFixed(1),
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(shadowBlur: value)),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildLayoutTab(
    SubtitlePrefs prefs,
    SubtitlePrefsNotifier notifier,
  ) {
    final l10n = context.l10n;
    return [
      SettingsSection(
        title: 'Position & Padding',
        children: [
          SettingsSliderTile(
            icon: Icons.vertical_align_bottom_rounded,
            title: l10n.subtitleBottomPadding,
            value: prefs.bottomPadding,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${prefs.bottomPadding.round()}px',
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(bottomPadding: value)),
          ),
          SettingsSliderTile(
            icon: Icons.padding_rounded,
            title: l10n.subtitleBgPadding,
            value: prefs.padding,
            min: 0,
            max: 30,
            divisions: 15,
            label: '${prefs.padding.round()}px',
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(padding: value)),
          ),
        ],
      ),
      SettingsSection(
        title: 'Spacing',
        children: [
          SettingsSliderTile(
            icon: Icons.format_line_spacing_rounded,
            title: l10n.subtitleLineHeight,
            value: prefs.lineHeight,
            min: 0.8,
            max: 2.0,
            divisions: 24,
            label: '${prefs.lineHeight.toStringAsFixed(2)}x',
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(lineHeight: value)),
          ),
          SettingsSliderTile(
            icon: Icons.space_bar_rounded,
            title: l10n.subtitleLetterSpacing,
            value: prefs.letterSpacing,
            min: -2.0,
            max: 5.0,
            divisions: 14,
            label: '${prefs.letterSpacing.toStringAsFixed(1)}px',
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(letterSpacing: value)),
          ),
          SettingsSliderTile(
            icon: Icons.notes_rounded,
            title: l10n.subtitleWordSpacing,
            value: prefs.wordSpacing,
            min: -3.0,
            max: 10.0,
            divisions: 26,
            label: '${prefs.wordSpacing.toStringAsFixed(1)}px',
            onChanged: (value) =>
                notifier.updatePrefs(prefs.copyWith(wordSpacing: value)),
          ),
        ],
      ),
    ];
  }
}

class _ColorStudioTile extends StatefulWidget {
  final String overline;
  final String title;
  final int currentValue;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _ColorStudioTile({
    required this.overline,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_ColorStudioTile> createState() => _ColorStudioTileState();
}

class _ColorStudioTileState extends State<_ColorStudioTile> {
  bool _expanded = false;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: _formatHex(widget.currentValue));
  }

  @override
  void didUpdateWidget(covariant _ColorStudioTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      final formatted = _formatHex(widget.currentValue);
      if (_hexController.text.toUpperCase() != formatted) {
        _hexController.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _formatHex(int value) =>
      value.toRadixString(16).padLeft(8, '0').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(widget.currentValue);
    final alphaPercent = ((color.a * 100).round()).clamp(0, 100);
    final isOff = widget.currentValue == 0x00000000;

    return SettingsCustomTile(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.overline,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOff
                                ? 'OFF'
                                : '#${_formatHex(widget.currentValue)} · $alphaPercent%',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isOff ? cs.surfaceContainerHighest : color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: isOff
                      ? Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.options.map((colorValue) {
                    final selected = widget.currentValue == colorValue;
                    final transparent = colorValue == 0x00000000;
                    final optColor = Color(colorValue);
                    final checkColor = transparent
                        ? cs.onSurface
                        : (optColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white);

                    return GestureDetector(
                      onTap: () => widget.onChanged(colorValue),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: transparent
                              ? cs.surfaceContainerHighest
                              : optColor,
                          border: Border.all(
                            color: selected
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.4),
                            width: selected ? 2.2 : 1,
                          ),
                        ),
                        child: selected
                            ? Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: checkColor,
                              )
                            : transparent
                            ? Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: cs.onSurfaceVariant,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: _expanded
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.colorize_rounded,
                        size: 13,
                        color: _expanded
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pick',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _expanded
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _InlineHsvAlphaPicker(
                      color: isOff ? const Color(0xFFFFFFFF) : color,
                      hexController: _hexController,
                      onChanged: (c) => widget.onChanged(c.toARGB32()),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InlineHsvAlphaPicker extends StatefulWidget {
  final Color color;
  final TextEditingController hexController;
  final ValueChanged<Color> onChanged;

  const _InlineHsvAlphaPicker({
    required this.color,
    required this.hexController,
    required this.onChanged,
  });

  @override
  State<_InlineHsvAlphaPicker> createState() => _InlineHsvAlphaPickerState();
}

class _InlineHsvAlphaPickerState extends State<_InlineHsvAlphaPicker> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(covariant _InlineHsvAlphaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color.toARGB32() != widget.color.toARGB32()) {
      final incoming = HSVColor.fromColor(widget.color);
      _hsv = _hsv.saturation == 0 || incoming.saturation > 0
          ? incoming
          : incoming.withHue(_hsv.hue);
    }
  }

  void _emit(HSVColor next) {
    setState(() => _hsv = next);
    widget.onChanged(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pureHue = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const height = 112.0;
            final dx = (_hsv.saturation * width).clamp(0.0, width);
            final dy = ((1 - _hsv.value) * height).clamp(0.0, height);

            void updateSv(Offset pos) {
              final s = (pos.dx / width).clamp(0.0, 1.0);
              final v = (1 - (pos.dy / height)).clamp(0.0, 1.0);
              _emit(_hsv.withSaturation(s).withValue(v));
            }

            return GestureDetector(
              onPanDown: (d) => updateSv(d.localPosition),
              onPanUpdate: (d) => updateSv(d.localPosition),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: height,
                  width: width,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(width, height),
                        painter: _SvBoxPainter(hueColor: pureHue),
                      ),
                      Positioned(
                        left: (dx - 9).clamp(0.0, width - 18),
                        top: (dy - 9).clamp(0.0, height - 18),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hsv.withAlpha(1).toColor(),
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _GradientBar(
          ratio: _hsv.hue / 360,
          colors: const [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
          thumbColor: pureHue,
          onChanged: (r) => _emit(_hsv.withHue((r * 360).clamp(0.0, 360.0))),
        ),
        const SizedBox(height: 8),
        _GradientBar(
          ratio: _hsv.alpha,
          colors: [
            _hsv.withAlpha(0).toColor(),
            _hsv.withAlpha(1).toColor(),
          ],
          thumbColor: _hsv.toColor(),
          onChanged: (r) => _emit(_hsv.withAlpha(r.clamp(0.0, 1.0))),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.hexController,
          maxLength: 8,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            counterText: '',
            prefixText: '#',
            isDense: true,
            labelText: context.l10n.subtitleHexCodeLabel,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) {
            if (val.length == 8) {
              final parsed = int.tryParse(val, radix: 16);
              if (parsed != null) widget.onChanged(Color(parsed));
            }
          },
        ),
      ],
    );
  }
}

class _GradientBar extends StatelessWidget {
  final double ratio;
  final List<Color> colors;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  const _GradientBar({
    required this.ratio,
    required this.colors,
    required this.thumbColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 16.0;
        final x = (ratio.clamp(0.0, 1.0) * (width - height));

        void update(Offset pos) =>
            onChanged((pos.dx / width).clamp(0.0, 1.0));

        return GestureDetector(
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          child: SizedBox(
            height: height,
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(colors: colors),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                Positioned(
                  left: x,
                  child: Container(
                    width: height,
                    height: height,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SvBoxPainter extends CustomPainter {
  final Color hueColor;

  const _SvBoxPainter({required this.hueColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SvBoxPainter oldDelegate) =>
      oldDelegate.hueColor != hueColor;
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
