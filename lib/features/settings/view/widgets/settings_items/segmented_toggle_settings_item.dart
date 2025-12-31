import 'package:flutter/material.dart';
import 'base_settings_item.dart';

class SegmentedToggleSettingsItem<T> extends BaseSettingsItem {
  final T selectedValue;
  final Map<T, Widget> children;
  final ValueChanged<int> onValueChanged;
  final Map<T, String>? labels;

  const SegmentedToggleSettingsItem({
    super.key,
    super.icon,
    super.iconColor,
    required super.accent,
    required super.title,
    required super.description,
    super.leading,
    super.roundness,
    super.isCompact,
    super.layoutType,
    required this.selectedValue,
    required this.children,
    required this.onValueChanged,
    this.labels,
  })  : assert(children.length > 1, "There must be at least 2 children."),
        super(onTap: null);

  @override
  bool needsVerticalLayoutByContent() => true;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    return Row(
      children: [
        buildIconContainer(effectiveCompact, dimensions),
        SizedBox(width: dimensions.spacing),
        buildTitleAndDescription(effectiveCompact, dimensions),
        SizedBox(width: dimensions.spacing),
        Expanded(
          flex: 2,
          child: _buildSegmentedToggle(context, effectiveCompact),
        ),
      ],
    );
  }

  @override
  Widget buildVerticalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            buildIconContainer(effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
            buildTitleAndDescription(effectiveCompact, dimensions,
                isVertical: true),
          ],
        ),
        SizedBox(height: effectiveCompact ? 8 : 12),
        _buildSegmentedToggle(context, effectiveCompact),
      ],
    );
  }

  Widget _buildSegmentedToggle(BuildContext context, bool effectiveCompact) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 12),
      ),
      child: Row(
        children: children.keys.map((key) {
          final isSelected = selectedValue == key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onValueChanged(key as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(2),
                padding: EdgeInsets.symmetric(
                  vertical: effectiveCompact ? 8 : 10,
                  horizontal: effectiveCompact ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? (iconColor ?? accent) : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(effectiveCompact ? 8 : 10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color:
                            isSelected ? Colors.white : (iconColor ?? accent),
                        size: effectiveCompact ? 16 : 18,
                      ),
                      child: children[key]!,
                    ),
                    if (!effectiveCompact &&
                        labels != null &&
                        labels![key] != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        labels![key]!,
                        style: TextStyle(
                          fontSize: effectiveCompact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : (iconColor ?? accent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
