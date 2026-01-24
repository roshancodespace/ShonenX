import 'package:flutter/material.dart';
import 'package:shonenx/features/settings/view/widgets/color_picker_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';

enum SettingsSectionLayout { list, grid }

class SettingsSection extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final VoidCallback? onTap;
  final List<Widget> children;

  // M3 Expressive Props
  final bool isExpressive;
  final double? roundness;

  // Grid layout properties
  final SettingsSectionLayout layout;
  final int gridColumns;
  final double gridCrossAxisSpacing;
  final double gridMainAxisSpacing;
  final double gridChildAspectRatio;

  const SettingsSection({
    super.key,
    required this.title,
    this.titleColor,
    this.onTap,
    required this.children,
    this.isExpressive = true,
    this.roundness,
    this.layout = SettingsSectionLayout.list,
    this.gridColumns = 2,
    this.gridCrossAxisSpacing = 8.0,
    this.gridMainAxisSpacing = 8.0,
    this.gridChildAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: titleColor ?? theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Children
        _buildItemsLayout(),
      ],
    );
  }

  Widget _buildItemsLayout() {
    switch (layout) {
      case SettingsSectionLayout.grid:
        return _buildGridLayout();
      case SettingsSectionLayout.list:
        return _buildListLayout();
    }
  }

  Widget _buildListLayout() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < children.length - 1 ? 6.0 : 0.0,
            ),
            child: _wrapChild(child, false),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: gridCrossAxisSpacing,
        mainAxisSpacing: gridMainAxisSpacing,
        childAspectRatio: gridChildAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return _wrapChild(children[index], true);
      },
    );
  }

  Widget _wrapChild(Widget child, bool isInGrid) {
    if (child is BaseSettingsItem) {
      final commonProps = _CommonSettingsProps(
        isExpressive: isExpressive,
        roundness: roundness,
        isCompact: isInGrid,
      );

      if (child is NormalSettingsItem) {
        return NormalSettingsItem(
          key: child.key,
          icon: child.icon,
          leading: child.leading,
          iconColor: child.iconColor,
          accent: child.accent,
          title: child.title,
          description: child.description,
          onTap: child.onTap,
          trailingWidgets: child.trailingWidgets,
          layoutType: child.layoutType,
          isExpressive: commonProps.isExpressive,
          roundness: commonProps.roundness,
          isCompact: commonProps.isCompact,
        );
      } else if (child is SelectableSettingsItem) {
        return SelectableSettingsItem(
          key: child.key,
          icon: child.icon,
          leading: child.leading,
          iconColor: child.iconColor,
          accent: child.accent,
          title: child.title,
          description: child.description,
          onTap: child.onTap,
          trailingWidgets: child.trailingWidgets,
          layoutType: child.layoutType,
          isSelected: child.isSelected,
          isInSelectionMode: child.isInSelectionMode,
          isExpressive: commonProps.isExpressive,
          roundness: commonProps.roundness,
          isCompact: commonProps.isCompact,
        );
      } else if (child is ToggleableSettingsItem) {
        return ToggleableSettingsItem(
          key: child.key,
          icon: child.icon,
          leading: child.leading,
          iconColor: child.iconColor,
          accent: child.accent,
          title: child.title,
          description: child.description,
          trailingWidgets: child.trailingWidgets,
          layoutType: child.layoutType,
          value: child.value,
          onChanged: child.onChanged,
          isExpressive: commonProps.isExpressive,
          roundness: commonProps.roundness,
          isCompact: commonProps.isCompact,
        );
      } else if (child is SliderSettingsItem) {
        return SliderSettingsItem(
          key: child.key,
          icon: child.icon,
          leading: child.leading,
          iconColor: child.iconColor,
          accent: child.accent,
          title: child.title,
          description: child.description,
          layoutType: child.layoutType,
          value: child.value,
          onChanged: child.onChanged,
          min: child.min,
          max: child.max,
          divisions: child.divisions,
          suffix: child.suffix,
          isExpressive: commonProps.isExpressive,
          roundness: commonProps.roundness,
          isCompact: commonProps.isCompact,
        );
      } else if (child is DropdownSettingsItem) {
        return DropdownSettingsItem(
          key: child.key,
          icon: child.icon,
          leading: child.leading,
          iconColor: child.iconColor,
          accent: child.accent,
          title: child.title,
          description: child.description,
          layoutType: child.layoutType,
          value: child.value,
          items: child.items,
          onChanged: child.onChanged,
          isExpressive: commonProps.isExpressive,
          roundness: commonProps.roundness,
          isCompact: commonProps.isCompact,
        );
      } else if (child is SegmentedToggleSettingsItem) {
        return _buildSegmentedToggle(child, commonProps);
      } else if (child is ColorPickerSettingsItem) {
        return ColorPickerSettingsItem(
          key: child.key,
          icon: child.icon,
          leading: child.leading,
          iconColor: child.iconColor,
          accent: child.accent,
          title: child.title,
          description: child.description,
          layoutType: child.layoutType,
          selectedColor: child.selectedColor,
          onColorChanged: child.onColorChanged,
          colors: child.colors,
          isExpressive: commonProps.isExpressive,
          roundness: commonProps.roundness,
          isCompact: commonProps.isCompact,
        );
      }
    }

    return child;
  }

  Widget _buildSegmentedToggle(
    SegmentedToggleSettingsItem item,
    _CommonSettingsProps props,
  ) {
    return SegmentedToggleSettingsItem<dynamic>(
      key: item.key,
      icon: item.icon,
      leading: item.leading,
      iconColor: item.iconColor,
      accent: item.accent,
      title: item.title,
      description: item.description,
      layoutType: item.layoutType,
      selectedValue: item.selectedValue,
      children: item.children,
      onValueChanged: item.onValueChanged,
      labels: item.labels,
      isExpressive: props.isExpressive,
      roundness: props.roundness,
      isCompact: props.isCompact,
    );
  }
}

class _CommonSettingsProps {
  final bool isExpressive;
  final double? roundness;
  final bool isCompact;

  _CommonSettingsProps({
    required this.isExpressive,
    this.roundness,
    required this.isCompact,
  });
}
