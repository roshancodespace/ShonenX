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
    required this.children, // <-- updated
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
      default:
        return _buildListLayout();
    }
  }

  Widget _buildListLayout() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
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
    if (child is SettingsItem) {
      // clone with adjustments
      return SettingsItem(
        icon: child.icon,
        leading: child.leading,
        iconColor: child.iconColor,
        accent: child.accent,
        title: child.title,
        description: child.description,
        onTap: child.onTap,
        roundness: roundness,
        type: child.type,
        isSelected: child.isSelected,
        isInSelectionMode: child.isInSelectionMode,
        toggleValue: child.toggleValue,
        onToggleChanged: child.onToggleChanged,
        sliderValue: child.sliderValue,
        sliderMin: child.sliderMin,
        sliderMax: child.sliderMax,
        sliderDivisions: child.sliderDivisions,
        sliderSuffix: child.sliderSuffix,
        onSliderChanged: child.onSliderChanged,
        dropdownValue: child.dropdownValue,
        dropdownItems: child.dropdownItems,
        onDropdownChanged: child.onDropdownChanged,
        isCompact: isInGrid,
        segmentedSelectedIndex: child.segmentedSelectedIndex,
        segmentedOptions: child.segmentedOptions,
        segmentedLabels: child.segmentedLabels,
        onSegmentedChanged: child.onSegmentedChanged,
        trailingWidgets: child.trailingWidgets,
        layoutType: child.layoutType,
      );
    }

    // Not a SettingsItem → just render directly
    return child;
  }
}

