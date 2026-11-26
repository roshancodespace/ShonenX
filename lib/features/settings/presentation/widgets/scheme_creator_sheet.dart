import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/theme/theme_color_resolver.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/m3e_dropdown.dart';
import 'package:shonenx/shared/widgets/m3e_split_button_group.dart';

enum _CreatorMode { seed, palette }

enum _PaletteRole { primary, secondary, tertiary, surface }

class SchemeCreatorSheet extends ConsumerStatefulWidget {
  const SchemeCreatorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: 750,
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      builder: (_) => const SchemeCreatorSheet(),
    );
  }

  @override
  ConsumerState<SchemeCreatorSheet> createState() => _SchemeCreatorSheetState();
}

class _SchemeCreatorSheetState extends ConsumerState<SchemeCreatorSheet> {
  static const _seedSwatches = <Color>[
    Color(0xFF5B6EFF),
    Color(0xFF00C2FF),
    Color(0xFF8B5CF6),
    Color(0xFFE50914),
    Color(0xFFFF5C8D),
    Color(0xFFFF640A),
    Color(0xFFFACC15),
    Color(0xFF10B981),
  ];

  late _CreatorMode _mode;
  _PaletteRole _activeRole = _PaletteRole.primary;
  bool _showInlinePicker = false;

  late Color _seedColor;
  late Color _primary;
  Color? _secondary;
  Color? _tertiary;
  Color? _surface;
  late AppThemeVariant _variant;
  late ThemeMode _previewMode;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(themePrefsProvider);
    _previewMode = prefs.themeMode;

    final isDark = _effectivePreviewDark(contextFallback: true);
    final resolved = resolveThemeColors(
      prefs,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    _mode = prefs.primaryColor != null
        ? _CreatorMode.palette
        : _CreatorMode.seed;
    _seedColor = prefs.colorSeed != null
        ? Color(prefs.colorSeed!)
        : resolved.primaryKey;
    _primary = prefs.primaryColor != null
        ? Color(prefs.primaryColor!)
        : resolved.primaryKey;
    _secondary = prefs.secondaryColor != null
        ? Color(prefs.secondaryColor!)
        : null;
    _tertiary = prefs.tertiaryColor != null
        ? Color(prefs.tertiaryColor!)
        : null;
    _surface = prefs.surfaceColor != null ? Color(prefs.surfaceColor!) : null;
    _variant = prefs.themeVariant;
  }

  bool _effectivePreviewDark({bool contextFallback = false}) {
    if (_previewMode == ThemeMode.dark) return true;
    if (_previewMode == ThemeMode.light) return false;
    if (contextFallback) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return Theme.of(context).brightness == Brightness.dark;
  }

  ColorScheme _buildPreviewScheme() {
    final brightness = _effectivePreviewDark()
        ? Brightness.dark
        : Brightness.light;
    final variant = toDynamicSchemeVariant(_variant);
    if (_mode == _CreatorMode.seed) {
      return ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
        dynamicSchemeVariant: variant,
      );
    }
    var scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: brightness,
      dynamicSchemeVariant: variant,
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
    );
    if (_surface != null) {
      scheme = scheme.copyWith(surface: _surface);
    }
    return scheme;
  }

  Color get _activeColor {
    if (_mode == _CreatorMode.seed) return _seedColor;
    return switch (_activeRole) {
      _PaletteRole.primary => _primary,
      _PaletteRole.secondary => _secondary ?? _primary,
      _PaletteRole.tertiary => _tertiary ?? _primary,
      _PaletteRole.surface =>
        _surface ??
            (_effectivePreviewDark()
                ? const Color(0xFF121318)
                : const Color(0xFFF8F9FC)),
    };
  }

  void _onInlineColorChanged(Color c) {
    setState(() {
      if (_mode == _CreatorMode.seed) {
        _seedColor = c;
      } else {
        switch (_activeRole) {
          case _PaletteRole.primary:
            _primary = c;
          case _PaletteRole.secondary:
            _secondary = c;
          case _PaletteRole.tertiary:
            _tertiary = c;
          case _PaletteRole.surface:
            _surface = c;
        }
      }
    });
  }

  String get _pickerLabel {
    if (_mode == _CreatorMode.seed) return 'Custom Seed Color';
    return switch (_activeRole) {
      _PaletteRole.primary => 'Primary Color',
      _PaletteRole.secondary => 'Secondary Color',
      _PaletteRole.tertiary => 'Tertiary Color',
      _PaletteRole.surface => 'Surface Color',
    };
  }

  void _apply() {
    final notifier = ref.read(themePrefsProvider.notifier);
    notifier.updateTheme(
      (p) => p.copyWith(themeVariant: _variant, themeMode: _previewMode),
    );
    if (_mode == _CreatorMode.seed) {
      notifier.setCustomColorSeed(_seedColor.toARGB32());
    } else {
      notifier.setCustomPalette(
        primaryArgb: _primary.toARGB32(),
        secondaryArgb: _secondary?.toARGB32(),
        tertiaryArgb: _tertiary?.toARGB32(),
        surfaceArgb: _surface?.toARGB32(),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = _buildPreviewScheme();
    final isCustomSeed = !_seedSwatches.any(
      (c) => c.toARGB32() == _seedColor.toARGB32(),
    );

    return AppBottomSheet(
      title: 'Scheme Creator',
      titleIcon: Icons.palette_rounded,
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: preview.primary,
            foregroundColor: preview.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
          ),
          onPressed: _apply,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text(
            'Apply',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live Preview Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: preview.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: preview.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${(preview.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                          style: TextStyle(
                            color: preview.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          '${_variant.displayName} • ${_effectivePreviewDark() ? 'Dark' : 'Light'}',
                          style: TextStyle(
                            color: preview.onSurfaceVariant,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TokenDot(color: preview.primary),
                  const SizedBox(width: 6),
                  _TokenDot(color: preview.primaryContainer),
                  const SizedBox(width: 6),
                  _TokenDot(color: preview.secondary),
                  const SizedBox(width: 6),
                  _TokenDot(color: preview.tertiary),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: preview.surfaceContainerHigh,
                      foregroundColor: preview.onSurfaceVariant,
                    ),
                    onPressed: () {
                      final next = switch (_previewMode) {
                        ThemeMode.light => ThemeMode.dark,
                        ThemeMode.dark => ThemeMode.system,
                        ThemeMode.system => ThemeMode.light,
                      };
                      setState(() => _previewMode = next);
                    },
                    icon: Icon(switch (_previewMode) {
                      ThemeMode.light => Icons.wb_sunny_outlined,
                      ThemeMode.dark => Icons.nightlight_round,
                      ThemeMode.system => Icons.smartphone_rounded,
                    }, size: 17),
                    tooltip: 'Cycle Light / Dark / System',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mode + Variant Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: M3eSplitButtonGroup<_CreatorMode>(
                    expandSegments: true,
                    height: 38,
                    segments: const [
                      ButtonSegment(
                        value: _CreatorMode.seed,
                        label: Text('Seed'),
                      ),
                      ButtonSegment(
                        value: _CreatorMode.palette,
                        label: Text('Palette'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: M3eDropdown<AppThemeVariant>(
                    value: _variant,
                    items: AppThemeVariant.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _variant = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step 1: Pick Seed Swatch or Palette Role
            if (_mode == _CreatorMode.seed)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final color in _seedSwatches)
                    _CircleSwatch(
                      color: color,
                      isSelected: color.toARGB32() == _seedColor.toARGB32(),
                      onTap: () => setState(() => _seedColor = color),
                    ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showInlinePicker = !_showInlinePicker),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCustomSeed || _showInlinePicker
                            ? _seedColor
                            : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _showInlinePicker
                              ? cs.primary
                              : (isCustomSeed
                                    ? cs.onSurface
                                    : cs.outlineVariant.withValues(alpha: 0.5)),
                          width: (_showInlinePicker || isCustomSeed) ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _showInlinePicker
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.colorize_rounded,
                        size: 18,
                        color: (isCustomSeed || _showInlinePicker)
                            ? (ThemeData.estimateBrightnessForColor(
                                        _seedColor,
                                      ) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            else
              _PaletteRoleRow(
                primary: _primary,
                secondary: _secondary ?? preview.secondary,
                tertiary: _tertiary ?? preview.tertiary,
                surface: _surface ?? preview.surface,
                hasCustomSecondary: _secondary != null,
                hasCustomTertiary: _tertiary != null,
                hasCustomSurface: _surface != null,
                activeRole: _showInlinePicker ? _activeRole : null,
                onTapRole: (role) {
                  setState(() {
                    if (_showInlinePicker && _activeRole == role) {
                      _showInlinePicker = false;
                    } else {
                      _activeRole = role;
                      _showInlinePicker = true;
                    }
                  });
                },
                onResetRole: (role) {
                  setState(() {
                    switch (role) {
                      case _PaletteRole.primary:
                        break;
                      case _PaletteRole.secondary:
                        _secondary = null;
                      case _PaletteRole.tertiary:
                        _tertiary = null;
                      case _PaletteRole.surface:
                        _surface = null;
                    }
                  });
                },
              ),

            // Step 2: Expandable Inline Color Wheel
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: _showInlinePicker
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _pickerLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _showInlinePicker = false),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme:
                                    const InputDecorationTheme(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      isDense: true,
                                    ),
                              ),
                              child: ColorPicker(
                                color: _activeColor,
                                onColorChanged: _onInlineColorChanged,
                                padding: EdgeInsets.zero,
                                width: 28,
                                height: 28,
                                borderRadius: 9,
                                spacing: 5,
                                runSpacing: 5,
                                wheelDiameter: 155,
                                wheelWidth: 14,
                                wheelHasBorder: false,
                                enableShadesSelection: true,
                                showColorCode: true,
                                colorCodeHasColor: true,
                                colorCodeTextStyle: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                copyPasteBehavior:
                                    const ColorPickerCopyPasteBehavior(
                                      ctrlC: true,
                                      ctrlV: true,
                                      copyButton: false,
                                      pasteButton: false,
                                    ),
                                pickersEnabled: const <ColorPickerType, bool>{
                                  ColorPickerType.both: false,
                                  ColorPickerType.primary: false,
                                  ColorPickerType.accent: false,
                                  ColorPickerType.bw: false,
                                  ColorPickerType.custom: false,
                                  ColorPickerType.wheel: true,
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenDot extends StatelessWidget {
  final Color color;
  const _TokenDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CircleSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CircleSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: isSelected
            ? Icon(Icons.check_rounded, size: 19, color: fg)
            : null,
      ),
    );
  }
}

class _PaletteRoleRow extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final bool hasCustomSecondary;
  final bool hasCustomTertiary;
  final bool hasCustomSurface;
  final _PaletteRole? activeRole;
  final ValueChanged<_PaletteRole> onTapRole;
  final ValueChanged<_PaletteRole> onResetRole;

  const _PaletteRoleRow({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.hasCustomSecondary,
    required this.hasCustomTertiary,
    required this.hasCustomSurface,
    required this.activeRole,
    required this.onTapRole,
    required this.onResetRole,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      (
        role: _PaletteRole.primary,
        label: 'Primary',
        color: primary,
        canReset: false,
      ),
      (
        role: _PaletteRole.secondary,
        label: 'Secondary',
        color: secondary,
        canReset: hasCustomSecondary,
      ),
      (
        role: _PaletteRole.tertiary,
        label: 'Tertiary',
        color: tertiary,
        canReset: hasCustomTertiary,
      ),
      (
        role: _PaletteRole.surface,
        label: 'Surface',
        color: surface,
        canReset: hasCustomSurface,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        final fg =
            ThemeData.estimateBrightnessForColor(item.color) == Brightness.dark
            ? Colors.white
            : Colors.black;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => onTapRole(item.role),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeRole == item.role
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.45),
                        width: activeRole == item.role ? 2.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: fg.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                if (item.canReset)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: GestureDetector(
                      onTap: () => onResetRole(item.role),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 11,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
