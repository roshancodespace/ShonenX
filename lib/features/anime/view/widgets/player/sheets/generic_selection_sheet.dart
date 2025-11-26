import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class GenericSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final int selectedIndex;
  final String Function(T item) displayBuilder;
  final void Function(int index) onItemSelected;

  const GenericSelectionSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.displayBuilder,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            if (items.isEmpty)
              const Center(child: Text("No options available"))
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedIndex == index;
                    return ListTile(
                      title: Text(displayBuilder(item)),
                      selected: isSelected,
                      trailing:
                          isSelected ? const Icon(Iconsax.tick_circle) : null,
                      onTap: () => onItemSelected(index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
