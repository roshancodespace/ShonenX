import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/utils/theme.dart';

class SettingsSection extends StatelessWidget {
  final BuildContext context;
  final String title;
  final List<Widget> items;
  final bool compact;
  final Widget? trailing;
  final VoidCallback? onTitleTap;
  final bool showDividers;

  const SettingsSection({
    super.key,
    required this.context,
    required this.title,
    required this.items,
    this.compact = false,
    this.trailing,
    this.onTitleTap,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              bottom: compact ? 8 : 12,
              top: 4,
            ),
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (onTitleTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    )
                  ]
                ],
              ),
            ),
          ),
          Card(
            elevation: 1,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                      ?.borderRadius ??
                  BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                      ?.borderRadius ??
                  BorderRadius.circular(12),
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      if (index > 0 && showDividers)
                        Divider(
                          height: 1,
                          indent: 60,
                          endIndent: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                        ),
                      item,
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool disabled;
  final Widget? trailing;
  final bool compact;
  final bool showIcon;
  final Color? iconColor;
  final String? semanticLabel;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.disabled = false,
    this.trailing,
    this.compact = false,
    this.showIcon = true,
    this.iconColor,
    this.semanticLabel,
  });

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: widget.semanticLabel ?? '${widget.title}: ${widget.description}',
      button: true,
      enabled: !widget.disabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: InkWell(
              onTap: widget.disabled ? null : widget.onTap,
              borderRadius: getCardBorderRadius(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: widget.compact ? 12 : 16),
                decoration: BoxDecoration(
                  color: _isHovered && !widget.disabled
                      ? theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius:
                      (theme.cardTheme.shape as RoundedRectangleBorder?)
                              ?.borderRadius ??
                          BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (widget.showIcon) ...[
                      _buildIconContainer(
                        context,
                        widget.icon,
                        widget.disabled,
                        widget.compact,
                        widget.iconColor,
                      ),
                      SizedBox(width: widget.compact ? 12 : 16),
                    ],
                    Expanded(
                      child: _buildItemContent(
                        context,
                        widget.title,
                        widget.description,
                        widget.disabled,
                        widget.compact,
                      ),
                    ),
                    widget.trailing != null
                        ? widget.trailing!
                        : Icon(
                            Iconsax.arrow_right_3,
                            size: widget.compact ? 18 : 20,
                            color: widget.disabled
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsItemDropdown<T> extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<T> options;
  final T selectedOption;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemDisplay;
  final bool disabled;
  final Color? iconColor;

  const SettingsItemDropdown({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
    required this.itemDisplay,
    this.disabled = false,
    this.iconColor,
  });

  @override
  State<SettingsItemDropdown<T>> createState() =>
      _SettingsItemDropdownState<T>();
}

class _SettingsItemDropdownState<T> extends State<SettingsItemDropdown<T>>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedText = widget.itemDisplay(widget.selectedOption);

    return Semantics(
      label:
          '${widget.title}: ${widget.description}, current value: $selectedText',
      button: true,
      enabled: !widget.disabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: InkWell(
              onTap: widget.disabled
                  ? null
                  : () {
                      // Open custom dropdown
                      _showCustomDropdown(context);
                    },
              borderRadius: getCardBorderRadius(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: _isHovered && !widget.disabled
                      ? theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius:
                      (theme.cardTheme.shape as RoundedRectangleBorder?)
                              ?.borderRadius ??
                          BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildIconContainer(
                      context,
                      widget.icon,
                      widget.disabled,
                      false,
                      widget.iconColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildItemContent(
                        context,
                        widget.title,
                        widget.description,
                        widget.disabled,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.disabled
                            ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: widget.disabled
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Iconsax.arrow_down_1,
                            size: 16,
                            color: widget.disabled
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDropdown(BuildContext context) async {
    final theme = Theme.of(context);

    final result = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      elevation: 8,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = option == widget.selectedOption;

                    return InkWell(
                      onTap: () => Navigator.of(context).pop(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.itemDisplay(option),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Iconsax.tick_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      widget.onChanged(result);
    }
  }
}

// New SettingsSwitch component for toggle settings
class SettingsSwitch extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;
  final bool compact;
  final Color? iconColor;
  final String? semanticLabel;

  const SettingsSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    this.compact = false,
    this.iconColor,
    this.semanticLabel,
  });

  @override
  State<SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<SettingsSwitch> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      toggled: widget.value,
      label: widget.semanticLabel ??
          '${widget.title}: ${widget.description}, ${widget.value ? 'enabled' : 'disabled'}',
      child: SettingsItem(
        icon: widget.icon,
        iconColor: widget.iconColor,
        title: widget.title,
        description: widget.description,
        compact: widget.compact,
        onTap: widget.disabled ? () {} : () => widget.onChanged(!widget.value),
        disabled: widget.disabled,
        trailing: Switch.adaptive(
          value: widget.value,
          onChanged: widget.disabled ? null : widget.onChanged,
        ),
      ),
    );
  }
}

// Enhanced SettingsSlider component for slider settings
class SettingsSlider extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueDisplay;
  final bool disabled;
  final bool compact;
  final Color? iconColor;

  const SettingsSlider({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.valueDisplay,
    this.disabled = false,
    this.compact = false,
    this.iconColor,
  });

  @override
  State<SettingsSlider> createState() => _SettingsSliderState();
}

class _SettingsSliderState extends State<SettingsSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(SettingsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = widget.valueDisplay != null
        ? widget.valueDisplay!(_currentValue)
        : _currentValue.toStringAsFixed(1);

    return Semantics(
      slider: true,
      value: displayValue,
      label: '${widget.title}: ${widget.description}',
      child: Column(
        children: [
          SettingsItem(
            icon: widget.icon,
            iconColor: widget.iconColor,
            title: widget.title,
            description: widget.description,
            onTap: () {},
            disabled: widget.disabled,
            compact: widget.compact,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.disabled
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.disabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 16, 10),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                trackShape: CustomTrackShape(),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Slider(
                value: _currentValue,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                onChanged: widget.disabled
                    ? null
                    : (value) {
                        setState(() {
                          _currentValue = value;
                        });
                        widget.onChanged(value);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom track shape to remove extra padding
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

// Function to allow for color manipulations
extension ColorExtension on Color {
  Color withValues(
      {required double alpha, double? red, double? green, double? blue}) {
    return Color.fromRGBO(
      (red ?? this.red).round(),
      (green ?? this.green).round(),
      (blue ?? this.blue).round(),
      alpha,
    );
  }
}

// Extracted common methods with improvements
Widget _buildIconContainer(BuildContext context, IconData icon, bool disabled,
    [bool compact = false, Color? customColor]) {
  final theme = Theme.of(context);
  final baseColor = customColor ?? theme.colorScheme.primary;

  return Container(
    padding: EdgeInsets.all(compact ? 8 : 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          baseColor.withValues(alpha: disabled ? 0.1 : 0.2),
          baseColor.withValues(alpha: disabled ? 0.05 : 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      boxShadow: disabled
          ? null
          : [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
    ),
    child: Icon(
      icon,
      size: compact ? 18 : 22,
      color: disabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
          : baseColor,
    ),
  );
}

Widget _buildItemContent(
    BuildContext context, String title, String description, bool disabled,
    [bool compact = false]) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: compact ? 14 : 16,
          fontWeight: FontWeight.w600,
          color: disabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface,
        ),
      ),
      SizedBox(height: compact ? 3 : 4),
      Text(
        description,
        style: TextStyle(
          fontSize: compact ? 12 : 14,
          color: disabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    ],
  );
}

// New component for a header section
class SettingsHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Color? accentColor;

  const SettingsHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
