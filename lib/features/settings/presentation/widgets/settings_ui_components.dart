import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/m3e_dropdown.dart';
import 'package:shonenx/shared/widgets/m3e_slider.dart';
import 'package:shonenx/shared/widgets/m3e_split_button_group.dart';

const _compactBreakpoint = 400.0;
const _narrowTileWidth = 360.0;
const _outerRadius = 24.0;
const _innerRadius = 8.0;
const _badgeRadius = 14.0;
const _groupGap = 3.0;
const _minTileHeight = 64.0;
const _morphDuration = Duration(milliseconds: 220);
const _sectionPadding = EdgeInsets.symmetric(horizontal: 12);
const _headerPadding = EdgeInsets.fromLTRB(16, 16, 16, 8);

extension _Responsive on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;
  bool get _isCompact => _width < _compactBreakpoint;
}

enum _Position { single, first, middle, last }

extension _PositionRadius on _Position {
  BorderRadius get radius {
    const outer = Radius.circular(_outerRadius);
    const inner = Radius.circular(_innerRadius);
    return switch (this) {
      _Position.single => const BorderRadius.all(outer),
      _Position.first => const BorderRadius.vertical(top: outer, bottom: inner),
      _Position.middle => const BorderRadius.all(inner),
      _Position.last => const BorderRadius.vertical(top: inner, bottom: outer),
    };
  }
}

class _GroupPosition extends InheritedWidget {
  final _Position position;

  const _GroupPosition({required this.position, required super.child});

  static _Position of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupPosition>()?.position ??
      _Position.single;

  @override
  bool updateShouldNotify(_GroupPosition oldWidget) =>
      position != oldWidget.position;
}

Text _title(
  ColorScheme colors,
  String text, {
  Color? color,
  int? maxLines,
  TextOverflow? overflow,
}) => Text(
  text,
  maxLines: maxLines,
  overflow: overflow,
  style: TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: color ?? colors.onSurface,
  ),
);

Text? _subtitle(
  ColorScheme colors,
  String? text, {
  Color? color,
  FontWeight? weight,
  int? maxLines,
  TextOverflow? overflow,
}) => text == null
    ? null
    : Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          fontWeight: weight,
          color: color ?? colors.onSurfaceVariant,
        ),
      );

TextStyle _sectionLabelStyle(ColorScheme colors) => TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.2,
  color: colors.primary,
);

class _SettingsStyleScope extends InheritedWidget {
  final SettingsStyle style;

  const _SettingsStyleScope({required this.style, required super.child});

  static SettingsStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SettingsStyleScope>()?.style;

  @override
  bool updateShouldNotify(_SettingsStyleScope oldWidget) =>
      style != oldWidget.style;
}

class _IconBadge extends ConsumerWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _IconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style =
        _SettingsStyleScope.maybeOf(context) ??
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    if (style == SettingsStyle.classic) {
      return Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary);
    }
    return SizedBox.square(
      dimension: context._isCompact ? 36 : 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(_badgeRadius),
        ),
        child: Icon(icon, size: 22, color: foreground),
      ),
    );
  }
}

Widget? _leading(
  ColorScheme colors,
  IconData? icon,
  Widget? leading, {
  Color? background,
  Color? foreground,
}) =>
    leading ??
    (icon == null
        ? null
        : _IconBadge(
            icon: icon,
            background: background ?? colors.secondaryContainer,
            foreground: foreground ?? colors.onSecondaryContainer,
          ));

class _Tile extends ConsumerStatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? body;
  final Widget Function(bool narrow)? control;
  final bool stackWhenNarrow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const _Tile({
    this.leading,
    this.title,
    this.subtitle,
    this.body,
    this.control,
    this.stackWhenNarrow = true,
    this.onTap,
    this.onLongPress,
    this.color,
    this.padding,
  });

  @override
  ConsumerState<_Tile> createState() => _TileState();
}

class _TileState extends ConsumerState<_Tile> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style =
        _SettingsStyleScope.maybeOf(context) ??
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    final radius = isClassic
        ? BorderRadius.circular(10)
        : (_pressed
              ? BorderRadius.circular(_outerRadius)
              : _GroupPosition.of(context).radius);
    final overlay = _pressed
        ? 0.12
        : (_hovered || _focused)
        ? 0.08
        : 0.0;
    final base = isClassic
        ? (widget.color ?? Colors.transparent)
        : (widget.color ?? colors.surfaceContainerHigh);
    final fill = overlay == 0
        ? base
        : (base == Colors.transparent
              ? colors.onSurface.withValues(alpha: overlay)
              : Color.alphaBlend(
                  colors.onSurface.withValues(alpha: overlay),
                  base,
                ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowTileWidth;
        final control = widget.control?.call(narrow);
        final stacked = narrow && widget.stackWhenNarrow && control != null;

        return AnimatedContainer(
          duration: _morphDuration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(color: fill, borderRadius: radius),
          foregroundDecoration: _focused
              ? BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: colors.primary, width: 2),
                )
              : null,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              canRequestFocus: widget.onTap != null,
              borderRadius: radius,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              onHighlightChanged: widget.onTap == null
                  ? null
                  : (v) => setState(() => _pressed = v),
              onHover: widget.onTap == null
                  ? null
                  : (v) => setState(() => _hovered = v),
              onFocusChange: widget.onTap == null
                  ? null
                  : (v) => setState(
                      () => _focused =
                          v &&
                          FocusManager.instance.highlightMode ==
                              FocusHighlightMode.traditional,
                    ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: isClassic ? 52.0 : _minTileHeight,
                ),
                child: Padding(
                  padding:
                      widget.padding ??
                      (isClassic
                          ? const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            )
                          : EdgeInsets.symmetric(
                              horizontal: narrow ? 12 : 16,
                              vertical: 12,
                            )),
                  child: Row(
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        SizedBox(width: isClassic ? 14 : (narrow ? 12 : 16)),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null) widget.title!,
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              widget.subtitle!,
                            ],
                            if (stacked) ...[
                              const SizedBox(height: 10),
                              SizedBox(width: double.infinity, child: control),
                            ],
                            if (widget.body != null) ...[
                              if (widget.title != null ||
                                  widget.subtitle != null)
                                const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: widget.body!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (control != null && !stacked) ...[
                        const SizedBox(width: 12),
                        control,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;

  const _InfoButton({required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline_rounded, size: 20),
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class SettingsGroupItem extends ConsumerWidget {
  final int index;
  final int count;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SettingsGroupItem({
    super.key,
    required this.index,
    required this.count,
    required this.child,
    this.padding,
  });

  _Position _positionOf() {
    if (count <= 1) return _Position.single;
    if (index == 0) return _Position.first;
    if (index == count - 1) return _Position.last;
    return _Position.middle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    return _SettingsStyleScope(
      style: style,
      child: Padding(
        padding:
            padding ??
            (isClassic
                ? const EdgeInsets.symmetric(horizontal: 10)
                : EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    index < count - 1 ? _groupGap : 0,
                  )),
        child: _GroupPosition(position: _positionOf(), child: child),
      ),
    );
  }
}

class SettingsGroup extends ConsumerWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const SettingsGroup({
    super.key,
    required this.children,
    this.padding,
  });

  _Position _positionOf(int index) {
    if (children.length == 1) return _Position.single;
    if (index == 0) return _Position.first;
    if (index == children.length - 1) return _Position.last;
    return _Position.middle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (children.isEmpty) return const SizedBox.shrink();
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    return _SettingsStyleScope(
      style: style,
      child: Padding(
        padding:
            padding ??
            (isClassic
                ? const EdgeInsets.symmetric(horizontal: 10)
                : _sectionPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0 && !isClassic) const SizedBox(height: _groupGap),
              _GroupPosition(position: _positionOf(i), child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    return _SettingsStyleScope(
      style: style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: isClassic
                ? const EdgeInsets.fromLTRB(10, 10, 10, 6)
                : _headerPadding,
            child: Text(title.toUpperCase(), style: _sectionLabelStyle(colors)),
          ),
          if (subtitle != null)
            Padding(
              padding: isClassic
                  ? const EdgeInsets.fromLTRB(10, 0, 10, 6)
                  : const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _subtitle(colors, subtitle),
            ),
          SettingsGroup(children: children),
          SizedBox(height: isClassic ? 12 : 16),
        ],
      ),
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SettingsNavTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Tile(
      stackWhenNarrow: false,
      leading: _leading(colors, icon, leading),
      title: _title(colors, title),
      subtitle: _subtitle(colors, subtitle),
      control: (_) =>
          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onInfoCallback;

  const SettingsSwitchTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.onInfoCallback,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Tile(
      stackWhenNarrow: false,
      leading: _leading(colors, icon, leading),
      title: _title(colors, title),
      subtitle: _subtitle(colors, subtitle),
      control: (_) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onInfoCallback != null) _InfoButton(onPressed: onInfoCallback!),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
              (states) => states.contains(WidgetState.selected)
                  ? const Icon(Icons.check_rounded)
                  : null,
            ),
          ),
        ],
      ),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}

class SettingsActionTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool isDestructive;
  final Color? accentColor;
  final Color? tileColor;
  final Color? foregroundColor;
  final int? titleMaxLines;
  final TextOverflow? titleOverflow;
  final int? subtitleMaxLines;
  final TextOverflow? subtitleOverflow;

  const SettingsActionTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.leading,
    this.trailing,
    this.isDestructive = false,
    this.accentColor,
    this.tileColor,
    this.foregroundColor,
    this.titleMaxLines = 1,
    this.titleOverflow = TextOverflow.ellipsis,
    this.subtitleMaxLines,
    this.subtitleOverflow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = isDestructive ? colors.onErrorContainer : foregroundColor;
    final badgeColor = tint ?? accentColor ?? colors.onSecondaryContainer;

    return _Tile(
      stackWhenNarrow: false,
      color: tileColor ?? (isDestructive ? colors.errorContainer : null),
      leading: _leading(
        colors,
        icon,
        leading,
        foreground: badgeColor,
        background: tint == null && accentColor == null
            ? null
            : badgeColor.withValues(alpha: 0.16),
      ),
      title: _title(
        colors,
        title,
        color: tint,
        maxLines: titleMaxLines,
        overflow: titleOverflow,
      ),
      subtitle: _subtitle(
        colors,
        subtitle,
        color: tint?.withValues(alpha: 0.8),
        maxLines: subtitleMaxLines,
        overflow: subtitleOverflow,
      ),
      control: trailing == null ? null : (_) => trailing!,
      onTap: onTap,
    );
  }
}

class SettingsSegmentedTile<T> extends ConsumerWidget {
  final String? title;
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final void Function(Set<T>)? onSelectionChanged;
  final EdgeInsetsGeometry? padding;

  const SettingsSegmentedTile({
    super.key,
    this.title,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final style =
        _SettingsStyleScope.maybeOf(context) ??
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackControl =
            constraints.maxWidth < 540 ||
            (segments.length >= 3 && constraints.maxWidth < 680);

        Widget buildButton({required bool expanded}) {
          if (!isClassic) {
            final group = M3eSplitButtonGroup<T>(
              segments: segments,
              selected: selected,
              onSelectionChanged: onSelectionChanged,
              expandSegments: expanded,
            );
            return expanded
                ? group
                : FittedBox(fit: BoxFit.scaleDown, child: group);
          }

          final button = SegmentedButton<T>(
            segments: segments,
            selected: selected,
            onSelectionChanged: onSelectionChanged,
            showSelectedIcon: !context._isCompact,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              backgroundColor: colors.surfaceContainerHighest,
              foregroundColor: colors.onSurfaceVariant,
              selectedBackgroundColor: colors.primary,
              selectedForegroundColor: colors.onPrimary,
              side: BorderSide.none,
            ),
          );
          return expanded
              ? SizedBox(width: double.infinity, child: button)
              : FittedBox(fit: BoxFit.scaleDown, child: button);
        }

        return _Tile(
          padding: padding,
          stackWhenNarrow: false,
          title: title == null
              ? null
              : Text(title!, style: _sectionLabelStyle(colors)),
          body: stackControl ? buildButton(expanded: true) : null,
          control: stackControl ? null : (_) => buildButton(expanded: false),
        );
      },
    );
  }
}

class SettingsRadioTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;

  const SettingsRadioTile({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;

    return _Tile(
      color: isSelected ? colors.primaryContainer : null,
      leading: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
      title: _title(
        colors,
        title,
        color: isSelected ? colors.onPrimaryContainer : null,
      ),
      onTap: onChanged == null ? null : () => onChanged!(value),
    );
  }
}

class SettingsSliderTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double>? onChanged;
  final FocusNode? focusNode;

  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 10,
    required this.label,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<SettingsSliderTile> {
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ??
      (_internalFocusNode ??= FocusNode(
        debugLabel: 'SettingsSliderTile_${widget.title}',
        onKeyEvent: _handleKeyEvent,
      ));

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _step(double direction) {
    final onChanged = widget.onChanged;
    final range = widget.max - widget.min;
    if (onChanged == null || range <= 0) return;

    final step = range / (widget.divisions > 0 ? widget.divisions : 20);
    final next = double.parse(
      (widget.value + direction * step)
          .clamp(widget.min, widget.max)
          .toStringAsFixed(4),
    );
    if (next != widget.value) onChanged(next);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      node.focusInDirection(TraversalDirection.up);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      node.focusInDirection(TraversalDirection.down);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _step(1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final leading = _leading(colors, widget.icon, null);

    return _Tile(
      stackWhenNarrow: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < _narrowTileWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (leading != null) ...[
                    leading,
                    SizedBox(width: narrow ? 12 : 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _title(colors, widget.title),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          _subtitle(colors, widget.subtitle)!,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SettingsValueChip(label: widget.label),
                ],
              ),
              const SizedBox(height: 10),
              M3ESlider(
                focusNode: _effectiveFocusNode,
                value: widget.value,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                label: widget.label,
                onChanged: widget.onChanged,
              ),
            ],
          );
        },
      ),
    );
  }
}

class SettingsDropdownTile<T> extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final VoidCallback? onInfoCallback;

  const SettingsDropdownTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.items,
    this.onChanged,
    this.selectedItemBuilder,
    this.onInfoCallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final style =
        _SettingsStyleScope.maybeOf(context) ??
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    return _Tile(
      leading: _leading(colors, icon, null),
      title: _title(colors, title),
      subtitle: _subtitle(colors, subtitle),
      control: (narrow) {
        final dropdown = isClassic
            ? Material(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      value: value,
                      items: items,
                      onChanged: onChanged,
                      isDense: true,
                      isExpanded: true,
                      focusColor: Colors.transparent,
                      icon: const Icon(Icons.expand_more_rounded),
                      dropdownColor: colors.surfaceContainerHigh,
                      alignment: AlignmentDirectional.centerStart,
                      borderRadius: BorderRadius.circular(16),
                      selectedItemBuilder: selectedItemBuilder,
                    ),
                  ),
                ),
              )
            : M3eDropdown<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                selectedItemBuilder: selectedItemBuilder,
              );
        final info = onInfoCallback == null
            ? null
            : _InfoButton(
                onPressed: onInfoCallback!,
                tooltip: context.l10n.settingsInfo,
              );

        if (narrow) {
          return Row(
            children: [
              Expanded(child: dropdown),
              if (info != null) info,
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info != null) info,
            SizedBox(
              width: (context._width * 0.3).clamp(110.0, 200.0),
              child: dropdown,
            ),
          ],
        );
      },
    );
  }
}

class SettingsSelectionTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onCustomize;
  final String? customizeLabel;
  final IconData customizeIcon;

  const SettingsSelectionTile({
    super.key,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.onSelect,
    this.onCustomize,
    this.customizeLabel,
    this.customizeIcon = Icons.edit_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = customizeLabel ?? context.l10n.settingsCustomize;

    return _Tile(
      color: isSelected ? colors.primaryContainer : null,
      onTap: onSelect,
      leading: _leading(
        colors,
        isSelected ? Icons.check_rounded : Icons.circle_outlined,
        leading,
        background: isSelected
            ? colors.primary
            : colors.surfaceContainerHighest,
        foreground: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
      ),
      title: _title(
        colors,
        title,
        color: isSelected ? colors.onPrimaryContainer : null,
      ),
      subtitle: _subtitle(
        colors,
        subtitle,
        color: isSelected ? colors.onPrimaryContainer : null,
        weight: isSelected ? FontWeight.w700 : FontWeight.normal,
      ),
      control: onCustomize == null
          ? null
          : (_) => FilledButton.tonalIcon(
              onPressed: onCustomize,
              icon: Icon(customizeIcon, size: 18),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
    );
  }
}

class SettingsValueChip extends StatelessWidget {
  final String label;

  const SettingsValueChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context._width * 0.4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsCustomTile extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  const SettingsCustomTile({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Tile(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 14),
      color: color,
      onTap: onTap,
      body: child,
    );
  }
}
