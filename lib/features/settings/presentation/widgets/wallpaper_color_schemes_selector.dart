import 'package:flutter/material.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/utils/wallpaper_processor.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_palette_showcase.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

class WallpaperColorSchemesSelector extends StatefulWidget {
  final String imagePath;
  final int? currentSeed;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const WallpaperColorSchemesSelector({
    super.key,
    required this.imagePath,
    required this.currentSeed,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<WallpaperColorSchemesSelector> createState() =>
      _WallpaperColorSchemesSelectorState();
}

class _WallpaperColorSchemesSelectorState
    extends State<WallpaperColorSchemesSelector> {
  List<WallpaperPaletteSeed>? _seeds;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final cached = WallpaperProcessor.getCachedPaletteSeeds(widget.imagePath);
    if (cached != null && cached.isNotEmpty) {
      _seeds = cached;
      _isLoading = false;
    } else {
      _loadSeeds();
    }
  }

  @override
  void didUpdateWidget(covariant WallpaperColorSchemesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      final cached = WallpaperProcessor.getCachedPaletteSeeds(widget.imagePath);
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _seeds = cached;
          _isLoading = false;
        });
      } else {
        _loadSeeds();
      }
    }
  }

  Future<void> _loadSeeds() async {
    setState(() => _isLoading = true);
    final seeds = await WallpaperProcessor.extractTopPaletteSeeds(
      widget.imagePath,
    );
    if (mounted) {
      setState(() {
        _seeds = seeds;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: SizedBox(
          height: 94,
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_seeds == null || _seeds!.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = _seeds!
        .map(
          (seed) => ThemePaletteItem.fromSeed(
            id: seed.color.toARGB32().toString(),
            label: seed.label,
            seedColor: seed.color,
            isDark: widget.isDark,
          ),
        )
        .toList();

    return ThemePaletteShelf(
      title: context.l10n.settingsTopGeneratedSchemes,
      countBadge: '${items.length} Palettes',
      items: items,
      selectedId: widget.currentSeed?.toString(),
      onSelect: (item) => widget.onSelect(int.parse(item.id)),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
    );
  }
}
