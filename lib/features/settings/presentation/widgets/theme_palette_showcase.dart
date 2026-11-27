import 'dart:ui' as ui;
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/core/theme/standard_schemes.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_button.dart';

class ThemePaletteItem {
  final String id;
  final String label;
  final String? subtitle;
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color tertiary;
  final Color? surface;

  const ThemePaletteItem({
    required this.id,
    required this.label,
    this.subtitle,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.tertiary,
    this.surface,
  });

  factory ThemePaletteItem.fromAppScheme({
    required AppScheme scheme,
    required AppSchemeData data,
    required bool isDark,
  }) {
    final colors = isDark ? data.dark : data.light;
    return ThemePaletteItem(
      id: scheme.name,
      label: data.name,
      subtitle: data.description,
      primary: colors.primary,
      primaryContainer: colors.primaryContainer,
      secondary: colors.secondary,
      tertiary: colors.tertiary,
    );
  }

  factory ThemePaletteItem.fromExclusive({
    required String key,
    required ExclusiveSchemeData data,
    required bool isDark,
  }) {
    final colors = isDark ? data.dark : data.light;
    return ThemePaletteItem(
      id: key,
      label: data.name,
      subtitle: data.description,
      primary: colors.primary,
      primaryContainer: colors.primaryContainer,
      secondary: colors.secondary,
      tertiary: colors.tertiary,
    );
  }

  factory ThemePaletteItem.fromSeed({
    required String id,
    required String label,
    required Color seedColor,
    required bool isDark,
    String? subtitle,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    return ThemePaletteItem(
      id: id,
      label: label,
      subtitle:
          subtitle ??
          '#${(seedColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      primary: scheme.primary,
      primaryContainer: scheme.primaryContainer,
      secondary: scheme.secondary,
      tertiary: scheme.tertiary,
    );
  }
}

class ThemePaletteSwatch extends StatelessWidget {
  final ThemePaletteItem item;
  final double width;
  final double height;
  final double borderRadius;

  const ThemePaletteSwatch({
    super.key,
    required this.item,
    this.width = 48,
    this.height = 24,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (borderRadius - 0.8).clamp(0.0, 999.0),
        ),
        child: CustomPaint(
          painter: _DiagonalStripesPainter([
            item.primary,
            item.primaryContainer,
            item.secondary,
            item.tertiary,
          ]),
        ),
      ),
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  final List<Color> colors;

  const _DiagonalStripesPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.7853981633974483); // -45 degrees

    // Use the visible core span (accounting for sqrt(2) projection and rounded
    // corners) and extend the first/last stripes to the outer edges so all 4
    // colors remain clearly visible without clipping.
    final span = (size.width + size.height) * 0.52;
    final stripeW = span / colors.length;
    final startX = -span / 2;
    final outer = size.width + size.height;

    for (var i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      final left = i == 0 ? -outer : startX + i * stripeW;
      final right = i == colors.length - 1 ? outer : startX + (i + 1) * stripeW;
      canvas.drawRect(
        Rect.fromLTRB(left, -outer, right + 0.5, outer),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class ThemePaletteCard extends ConsumerStatefulWidget {
  final ThemePaletteItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const ThemePaletteCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.width = 148,
    this.height = 96,
  });

  @override
  ConsumerState<ThemePaletteCard> createState() => _ThemePaletteCardState();
}

class _ThemePaletteCardState extends ConsumerState<ThemePaletteCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    final radius = isClassic ? 10.0 : (_pressed ? 24.0 : 20.0);
    final baseColor = isClassic
        ? (widget.isSelected
              ? cs.primaryContainer.withValues(alpha: 0.28)
              : cs.surfaceContainerLow)
        : (widget.isSelected ? cs.primaryContainer : cs.surfaceContainerHigh);

    final overlay = _pressed ? 0.12 : (_hovered ? 0.08 : 0.0);
    final fill = overlay == 0
        ? baseColor
        : Color.alphaBlend(cs.onSurface.withValues(alpha: overlay), baseColor);

    final titleColor = (!isClassic && widget.isSelected)
        ? cs.onPrimaryContainer
        : (widget.isSelected ? cs.primary : cs.onSurface);
    final subtitleColor = (!isClassic && widget.isSelected)
        ? cs.onPrimaryContainer.withValues(alpha: 0.78)
        : cs.onSurfaceVariant;

    return AnimatedScale(
      scale: (!isClassic && _pressed) ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: widget.isSelected
                ? cs.primary
                : (isClassic
                      ? cs.outlineVariant.withValues(alpha: 0.25)
                      : Colors.transparent),
            width: widget.isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(radius),
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onHover: (v) => setState(() => _hovered = v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ThemePaletteSwatch(
                        item: widget.item,
                        width: 56,
                        height: 24,
                        borderRadius: isClassic ? 6 : 999,
                      ),
                      if (widget.isSelected)
                        Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          size: 18,
                          color: cs.primary,
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: widget.isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      if (widget.item.subtitle != null &&
                          widget.item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          widget.item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.0,
                            color: subtitleColor,
                            fontFeatures: const [ui.FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemePaletteTile extends ConsumerWidget {
  final ThemePaletteItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const ThemePaletteTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 2.0),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;
    final radius = isClassic ? 10.0 : 20.0;

    return Padding(
      padding: margin,
      child: Material(
        color: isSelected
            ? (isClassic
                  ? cs.primaryContainer.withValues(alpha: 0.25)
                  : cs.primaryContainer)
            : (isClassic ? Colors.transparent : cs.surfaceContainerHigh),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: isSelected
                ? cs.primary
                : (isClassic
                      ? cs.outlineVariant.withValues(alpha: 0.2)
                      : Colors.transparent),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                ThemePaletteSwatch(
                  item: item,
                  width: 44,
                  height: 24,
                  borderRadius: isClassic ? 6 : 999,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      if (item.subtitle != null &&
                          item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    size: 20,
                    color: cs.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThemePaletteShelf extends ConsumerWidget {
  final String title;
  final String? countBadge;
  final List<ThemePaletteItem> items;
  final String? selectedId;
  final ValueChanged<ThemePaletteItem> onSelect;
  final VoidCallback? onViewAll;
  final double cardWidth;
  final double cardHeight;
  final EdgeInsetsGeometry? padding;

  const ThemePaletteShelf({
    super.key,
    required this.title,
    this.countBadge,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.onViewAll,
    this.cardWidth = 148,
    this.cardHeight = 96,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    if (items.isEmpty) return const SizedBox.shrink();

    final headerPad = isClassic
        ? const EdgeInsets.fromLTRB(10, 8, 10, 6)
        : const EdgeInsets.fromLTRB(16, 12, 12, 8);
    final listPad = isClassic
        ? const EdgeInsets.symmetric(horizontal: 10)
        : const EdgeInsets.symmetric(horizontal: 12);

    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: isClassic ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: headerPad,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: cs.primary,
                      ),
                    ),
                    if (countBadge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isClassic
                              ? cs.primary.withValues(alpha: 0.12)
                              : cs.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            isClassic ? 6 : 999,
                          ),
                        ),
                        child: Text(
                          countBadge!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isClassic
                                ? cs.primary
                                : cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onViewAll != null)
                  AppButton(
                    label: context.l10n.homeViewAll,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    trailing: const Icon(CupertinoIcons.chevron_forward),
                    onPressed: onViewAll,
                  ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              padding: listPad,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(width: isClassic ? 8 : 6),
              itemBuilder: (context, index) {
                final item = items[index];
                return ThemePaletteCard(
                  item: item,
                  isSelected: selectedId == item.id,
                  onTap: () => onSelect(item),
                  width: cardWidth,
                  height: cardHeight,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
