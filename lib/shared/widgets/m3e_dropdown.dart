import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Material 3 Expressive dropdown with a pill trigger, animated chevron,
/// and a floating grouped-card menu using [OverlayPortal].
class M3eDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final String hint;
  final bool isExpanded;

  const M3eDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.selectedItemBuilder,
    this.hint = 'Choose an option',
    this.isExpanded = true,
  });

  @override
  State<M3eDropdown<T>> createState() => _M3eDropdownState<T>();
}

class _M3eDropdownState<T> extends State<M3eDropdown<T>>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  Size _triggerSize = Size.zero;
  bool _openAbove = false;
  bool _isOpen = false;
  double _menuWidth = 180.0;
  double _menuMaxHeight = 280.0;
  double _horizontalOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (widget.onChanged == null || widget.items.isEmpty) return;
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final offset = renderBox.localToGlobal(Offset.zero);
      final media = MediaQuery.of(context);
      final screenW = media.size.width;
      final screenH = media.size.height;
      final minLeft = media.padding.left + 12.0;
      final maxRight = screenW - media.padding.right - 12.0;
      final maxAllowedW = math.max(120.0, maxRight - minLeft);

      _triggerSize = renderBox.size;
      _menuWidth = math.min(math.max(_triggerSize.width, 180.0), maxAllowedW);

      var dx = 0.0;
      if (offset.dx + _menuWidth > maxRight) {
        dx = maxRight - _menuWidth - offset.dx;
      }
      if (offset.dx + dx < minLeft) {
        dx = minLeft - offset.dx;
      }
      _horizontalOffset = dx;

      final spaceBelow =
          screenH - media.padding.bottom - 12.0 - (offset.dy + _triggerSize.height);
      final spaceAbove = offset.dy - (media.padding.top + 12.0);
      final estimatedMenuH = math.min(widget.items.length * 48.0 + 16.0, 280.0);
      _openAbove = spaceBelow < estimatedMenuH && spaceAbove > spaceBelow;

      final availableH = _openAbove ? spaceAbove : spaceBelow;
      _menuMaxHeight = math.min(280.0, math.max(120.0, availableH - 6.0));
    }

    setState(() => _isOpen = true);
    _overlayController.show();
    _animController.forward(from: 0.0);
  }

  Future<void> _closeMenu() async {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    await _animController.reverse();
    if (mounted && _overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  Widget _buildSelectedDisplay(ColorScheme cs) {
    if (widget.selectedItemBuilder != null) {
      final built = widget.selectedItemBuilder!(context);
      final idx = widget.items.indexWhere((i) => i.value == widget.value);
      if (idx >= 0 && idx < built.length) {
        return built[idx];
      }
    }

    final selectedItem = widget.items.cast<DropdownMenuItem<T>?>().firstWhere(
      (i) => i?.value == widget.value,
      orElse: () => null,
    );

    if (selectedItem != null) {
      return DefaultTextStyle.merge(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        child: selectedItem.child,
      );
    }

    return Text(
      widget.hint,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  BorderRadius _itemRadius(int index, int total) {
    const outer = Radius.circular(16);
    const inner = Radius.circular(6);
    if (total <= 1) return const BorderRadius.all(outer);
    if (index == 0) {
      return const BorderRadius.vertical(top: outer, bottom: inner);
    }
    if (index == total - 1) {
      return const BorderRadius.vertical(top: inner, bottom: outer);
    }
    return const BorderRadius.all(inner);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.onChanged != null && widget.items.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (overlayContext) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeMenu,
                ),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: _openAbove
                    ? Alignment.topLeft
                    : Alignment.bottomLeft,
                followerAnchor: _openAbove
                    ? Alignment.bottomLeft
                    : Alignment.topLeft,
                offset: Offset(_horizontalOffset, _openAbove ? -6 : 6),
                child: FadeTransition(
                  opacity: _expandAnim,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.94,
                      end: 1.0,
                    ).animate(_expandAnim),
                    alignment: _openAbove
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: _menuWidth,
                        constraints: BoxConstraints(maxHeight: _menuMaxHeight),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < widget.items.length; i++) ...[
                                if (i > 0) const SizedBox(height: 3),
                                _M3eDropdownItem<T>(
                                  item: widget.items[i],
                                  isSelected:
                                      widget.items[i].value == widget.value,
                                  radius: _itemRadius(i, widget.items.length),
                                  onTap: () async {
                                    final val = widget.items[i].value;
                                    await _closeMenu();
                                    widget.items[i].onTap?.call();
                                    widget.onChanged?.call(val);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? _toggleMenu : null,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
              child: Row(
                mainAxisSize: widget.isExpanded
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  if (widget.isExpanded)
                    Expanded(child: _buildSelectedDisplay(cs))
                  else
                    Flexible(child: _buildSelectedDisplay(cs)),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
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

class _M3eDropdownItem<T> extends StatelessWidget {
  final DropdownMenuItem<T> item;
  final bool isSelected;
  final BorderRadius radius;
  final VoidCallback onTap;

  const _M3eDropdownItem({
    required this.item,
    required this.isSelected,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isSelected ? cs.primaryContainer : cs.surfaceContainer;
    final fg = isSelected ? cs.onPrimaryContainer : cs.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: item.enabled ? onTap : null,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    child: item.child,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_rounded, size: 17, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

