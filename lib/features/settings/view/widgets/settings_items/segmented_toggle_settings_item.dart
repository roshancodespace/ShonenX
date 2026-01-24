import 'package:flutter/material.dart';
import 'base_settings_item.dart';

class SegmentedToggleSettingsItem<T> extends BaseSettingsItem {
  final T selectedValue;
  final Map<T, Widget> children;
  final ValueChanged<T> onValueChanged;
  final Map<T, String>? labels;

  const SegmentedToggleSettingsItem({
    super.key,
    super.icon,
    super.iconColor,
    super.accent,
    required super.title,
    super.description,
    super.leading,
    super.isExpressive,
    super.roundness,
    super.containerColor,
    super.isCompact,
    super.layoutType,
    required this.selectedValue,
    required this.children,
    required this.onValueChanged,
    this.labels,
  }) : assert(children.length > 1, "There must be at least 2 children."),
       super(onTap: null);

  SegmentedToggleSettingsItem<T> copyWith({
    bool? isExpressive,
    bool? isCompact,
    double? roundness,
  }) {
    return SegmentedToggleSettingsItem<T>(
      key: key,
      icon: icon,
      leading: leading,
      iconColor: iconColor,
      accent: accent,
      title: title,
      description: description,
      layoutType: layoutType,
      selectedValue: selectedValue,
      children: children,
      onValueChanged: onValueChanged,
      labels: labels,
      isExpressive: isExpressive ?? this.isExpressive,
      isCompact: isCompact ?? this.isCompact,
      roundness: roundness ?? this.roundness,
    );
  }

  @override
  bool needsVerticalLayoutByContent() => true;

  @override
  Widget buildHorizontalLayout(
    BuildContext context,
    bool effectiveCompact,
    ResponsiveDimensions dimensions,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null || leading != null) ...[
            buildIconContainer(context, effectiveCompact, dimensions),
            SizedBox(width: dimensions.spacing),
          ],
          buildTitleAndDescription(context, effectiveCompact, dimensions),
          SizedBox(width: dimensions.spacing),
          Expanded(
            flex: 2,
            child: Center(
              child: _buildSegmentedToggle(context, effectiveCompact),
            ),
          ),
        ],
      ),
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
            if (icon != null || leading != null) ...[
              buildIconContainer(context, effectiveCompact, dimensions),
              SizedBox(width: dimensions.spacing),
            ],
            buildTitleAndDescription(
              context,
              effectiveCompact,
              dimensions,
              isVertical: true,
            ),
          ],
        ),
        SizedBox(height: effectiveCompact ? 12 : 16),
        _buildSegmentedToggle(context, effectiveCompact),
      ],
    );
  }

  Widget _buildSegmentedToggle(BuildContext context, bool effectiveCompact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveAccent = accent ?? colorScheme.primary;

    final outerRadius = BorderRadius.circular(effectiveCompact ? 12 : 14);
    final innerRadius = BorderRadius.circular(effectiveCompact ? 10 : 12);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: outerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children.keys.map((key) {
          final isSelected = selectedValue == key;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onValueChanged(key),
                borderRadius: innerRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  padding: EdgeInsets.symmetric(
                    vertical: effectiveCompact ? 8 : 10,
                    horizontal: effectiveCompact ? 8 : 12,
                  ),
                  decoration: ShapeDecoration(
                    color: isSelected ? effectiveAccent : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: innerRadius),
                    shadows: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
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
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          size: effectiveCompact ? 18 : 20,
                        ),
                        child: children[key]!,
                      ),
                      if (labels != null && labels![key] != null) ...[
                        if (!effectiveCompact || isSelected) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              labels![key]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
