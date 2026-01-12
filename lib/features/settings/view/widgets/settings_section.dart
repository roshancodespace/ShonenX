import 'package:flutter/material.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';

enum SettingsSectionLayout {
  list,
  grid,
}

class SettingsSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final VoidCallback? onTap;
  final List<Widget> children;
  final double roundness;

  // Grid layout properties
  final SettingsSectionLayout layout;
  final int gridColumns;
  final double gridCrossAxisSpacing;
  final double gridMainAxisSpacing;
  final double gridChildAspectRatio;

  const SettingsSection({
    super.key,
    required this.title,
    required this.titleColor,
    this.onTap,
    required this.children,
    this.roundness = 12,
    this.layout = SettingsSectionLayout.list,
    this.gridColumns = 2,
    this.gridCrossAxisSpacing = 8.0,
    this.gridMainAxisSpacing = 8.0,
    this.gridChildAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
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
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < children.length - 1 ? 5.0 : 0.0,
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
          roundness: roundness,
          trailingWidgets: child.trailingWidgets,
          layoutType: child.layoutType,
          focusNode: child.focusNode,
          autofocus: child.autofocus,
          isCompact: isInGrid,
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
          roundness: roundness,
          trailingWidgets: child.trailingWidgets,
          layoutType: child.layoutType,
          focusNode: child.focusNode,
          autofocus: child.autofocus,
          isSelected: child.isSelected,
          isInSelectionMode: child.isInSelectionMode,
          isCompact: isInGrid,
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
          roundness: roundness,
          trailingWidgets: child.trailingWidgets,
          layoutType: child.layoutType,
          focusNode: child.focusNode,
          autofocus: child.autofocus,
          value: child.value,
          onChanged: child.onChanged,
          isCompact: isInGrid,
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
          roundness: roundness,
          layoutType: child.layoutType,
          focusNode: child.focusNode,
          autofocus: child.autofocus,
          value: child.value,
          onChanged: child.onChanged,
          min: child.min,
          max: child.max,
          divisions: child.divisions,
          suffix: child.suffix,
          isCompact: isInGrid,
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
          roundness: roundness,
          layoutType: child.layoutType,
          focusNode: child.focusNode,
          autofocus: child.autofocus,
          value: child.value,
          items: child.items,
          onChanged: (String? value) => child.onChanged(value),
          isCompact: isInGrid,
        );
      } else if (child is SegmentedToggleSettingsItem) {
        return SegmentedToggleSettingsItem(
          key: child.key,
          icon: child.icon,
          leading: child.leading,
          iconColor: child.iconColor,
          accent: child.accent,
          title: child.title,
          description: child.description,
          roundness: roundness,
          layoutType: child.layoutType,
          focusNode: child.focusNode,
          autofocus: child.autofocus,
          selectedValue: child.selectedValue,
          children: child.children,
          onValueChanged: (int value) => child.onValueChanged(value),
          labels: child.labels,
          autofocusSegments: child.autofocusSegments,
          isCompact: isInGrid,
        );
      }
    }

    // If it's not a SettingsItem, render it directly.
    return child;
  }
}
