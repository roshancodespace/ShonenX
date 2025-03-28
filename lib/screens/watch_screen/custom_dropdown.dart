import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomDropdown extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<String> items;
  final Widget Function(String)? itemBuilder;
  final void Function(String) onChanged;

  const CustomDropdown({
    super.key,
    required this.icon,
    required this.value,
    required this.items,
    this.itemBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uniqueItems = items.toSet().toList();
    final validValue = uniqueItems.contains(value) ? value : uniqueItems.first;

    return GestureDetector(
      onTap: () => _showDropdownMenu(context, uniqueItems, validValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(  // Pushes the arrow icon to the right
              child: itemBuilder?.call(validValue) ??
                  Text(
                    validValue.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ),
            Icon(Iconsax.arrow_down_1,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showDropdownMenu(
      BuildContext context, List<String> uniqueItems, String currentValue) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + box.size.height,
        position.dx + box.size.width,
        0,
      ),
      items: uniqueItems
          .map((item) => PopupMenuItem<String>(
                value: item,
                child: Container(
                  width: box.size.width,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: itemBuilder?.call(item) ??
                      Text(
                        item.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
              ))
          .toList(),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ).then((selected) {
      if (selected != null && selected != currentValue) {
        onChanged(selected);
      }
    });
  }
}
