import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';

class AddRepoDialog extends StatefulWidget {
  final Future<void> Function(List<String> repoUrl, ItemType type) onRepoSaved;
  final void Function(String currentLanguage) onLanguageChanged;

  const AddRepoDialog({
    super.key,
    required this.onRepoSaved,
    required this.onLanguageChanged,
  });

  @override
  State<AddRepoDialog> createState() => _AddRepoDialogState();
}

class _AddRepoDialogState extends State<AddRepoDialog> {
  final TextEditingController _controller = TextEditingController();
  ItemType _selectedType = ItemType.anime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Repository'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<ItemType>(
              items: ItemType.values
                  .map(
                    (item) => DropdownMenuItem<ItemType>(
                      value: item,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              value: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Repository URL'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              widget.onRepoSaved([_controller.text], _selectedType),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
