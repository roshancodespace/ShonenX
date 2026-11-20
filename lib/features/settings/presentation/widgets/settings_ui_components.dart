// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shonenx/core/localization/l10n_extension.dart';

const _tileContentPadding = EdgeInsets.symmetric(horizontal: 10);
const _tileTitleStyle = TextStyle(fontWeight: FontWeight.w600);
const _sectionHeaderPadding = EdgeInsets.fromLTRB(10, 10, 10, 6);
const _chevronSize = 20.0;

TextStyle _subtitleStyle(ColorScheme colors) => TextStyle(
      fontSize: 12,
      color: colors.onSurfaceVariant,
    );

TextStyle _sectionLabelStyle(ColorScheme colors) => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: colors.primary,
    );

class SettingsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _sectionHeaderPadding,
          child: Text(
            title.toUpperCase(),
            style: _sectionLabelStyle(colors),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: _tileContentPadding,
            child: Text(
              subtitle!,
              style: _subtitleStyle(colors),
            ),
          ),
        Padding(
          padding: _tileContentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: _tileContentPadding,
      leading:
          leading ??
          (icon != null ? Icon(icon, color: theme.colorScheme.primary) : null),
      title: Text(title, style: _tileTitleStyle),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: _subtitleStyle(theme.colorScheme),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        size: _chevronSize,
        color: theme.colorScheme.onSurfaceVariant,
      ),
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: _tileContentPadding,
      leading:
          leading ??
          (icon != null ? Icon(icon, color: theme.colorScheme.primary) : null),
      title: Text(title, style: _tileTitleStyle),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: _subtitleStyle(theme.colorScheme),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onInfoCallback != null)
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
              onPressed: onInfoCallback,
            ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
      onTap: onChanged != null ? () => onChanged!(!value) : null,
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
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : foregroundColor;

    return ListTile(
      contentPadding: _tileContentPadding,
      tileColor: tileColor,
      textColor: color,
      iconColor: color,
      leading:
          leading ??
          (icon != null
              ? Icon(
                  icon,
                  color: color ?? accentColor ?? theme.colorScheme.primary,
                )
              : null),
      title: Text(
        title,
        maxLines: titleMaxLines,
        overflow: titleOverflow,
        style: _tileTitleStyle.copyWith(color: color),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              maxLines: subtitleMaxLines,
              overflow: subtitleOverflow,
              style: _subtitleStyle(theme.colorScheme),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class SettingsSegmentedTile<T> extends StatelessWidget {
  final String? title;
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final void Function(Set<T>)? onSelectionChanged;
  final EdgeInsetsGeometry padding;

  const SettingsSegmentedTile({
    super.key,
    this.title,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: _sectionLabelStyle(theme.colorScheme),
            ),
            const SizedBox(height: 12),
          ],
          SegmentedButton<T>(
            segments: segments,
            selected: selected,
            onSelectionChanged: onSelectionChanged,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
          ),
        ],
      ),
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
    return RadioListTile<T>(
      contentPadding: _tileContentPadding,
      title: Text(title, style: _tileTitleStyle),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
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
      widget.focusNode ?? (_internalFocusNode ??= _createFocusNode());

  FocusNode _createFocusNode() {
    return FocusNode(
      debugLabel: 'SettingsSliderTile_${widget.title}',
      onKeyEvent: _handleKeyEvent,
    );
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  double _calculateNewValue(double delta) {
    final range = widget.max - widget.min;
    if (range <= 0) return widget.value;

    final step = widget.divisions > 0 ? range / widget.divisions : range / 20.0;
    final rawNewValue = (widget.value + delta * step).clamp(
      widget.min,
      widget.max,
    );

    if (widget.divisions > 0) {
      final fraction = (rawNewValue - widget.min) / range;
      final roundedFraction =
          (fraction * widget.divisions).round() / widget.divisions;
      final stepped = widget.min + roundedFraction * range;
      return double.parse(
        stepped.clamp(widget.min, widget.max).toStringAsFixed(4),
      );
    }
    return rawNewValue;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        node.focusInDirection(TraversalDirection.up);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        node.focusInDirection(TraversalDirection.down);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (widget.onChanged != null) {
          final next = _calculateNewValue(1.0);
          if (next != widget.value) {
            widget.onChanged!(next);
          }
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (widget.onChanged != null) {
          final next = _calculateNewValue(-1.0);
          if (next != widget.value) {
            widget.onChanged!(next);
          }
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: _tileContentPadding,
      leading: Icon(widget.icon, color: theme.colorScheme.primary),
      title: Text(
        widget.title,
        style: _tileTitleStyle,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              style: _subtitleStyle(theme.colorScheme),
            ),
          Slider.adaptive(
            focusNode: _effectiveFocusNode,
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: widget.label,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

class SettingsDropdownTile<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: _tileContentPadding,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: _tileTitleStyle),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: _subtitleStyle(theme.colorScheme),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onInfoCallback != null) ...[
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
              tooltip: context.l10n.settingsInfo,
              onPressed: onInfoCallback,
            ),
            const SizedBox(width: 4),
          ],
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isDense: true,
              alignment: AlignmentDirectional.centerEnd,
              borderRadius: BorderRadius.circular(12),
              selectedItemBuilder: selectedItemBuilder,
            ),
          ),
        ],
      ),
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: _tileContentPadding,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.3,
      ),
      selectedColor: theme.colorScheme.primary,
      leading:
          leading ??
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
      title: Text(title, style: _tileTitleStyle),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
        ),
      ),
      onTap: onSelect,
      trailing: onCustomize != null
          ? FilledButton.icon(
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
              ),
              onPressed: onCustomize,
              icon: Icon(customizeIcon, size: 18),
              label: Text(customizeLabel ?? context.l10n.settingsCustomize),
            )
          : null,
    );
  }
}

class SettingsValueChip extends StatelessWidget {
  final String label;

  const SettingsValueChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      ),
    );
  }
}
