import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 6.0),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ],
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
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

  const SettingsSwitchTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
      secondary:
          leading ??
          (icon != null ? Icon(icon, color: theme.colorScheme.primary) : null),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : foregroundColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
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
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: theme.colorScheme.primary,
              ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}

class SettingsSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double>? onChanged;

  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 10,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider.adaptive(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class SettingsDropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const SettingsDropdownTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
        ),
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
  final String customizeLabel;
  final IconData customizeIcon;

  const SettingsSelectionTile({
    super.key,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.onSelect,
    this.onCustomize,
    this.customizeLabel = 'Customize',
    this.customizeIcon = Icons.edit_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      selected: isSelected,
      selectedTileColor:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      selectedColor: theme.colorScheme.primary,
      leading: leading ??
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
              label: Text(customizeLabel),
            )
          : null,
    );
  }
}
