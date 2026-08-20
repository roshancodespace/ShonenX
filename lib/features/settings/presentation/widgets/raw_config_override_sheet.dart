import 'package:flutter/material.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';

class RawConfigOverrideSheet {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
    String hintText = 'e.g. key=value or property override per line',
  }) {
    final controller = TextEditingController(text: initialValue);
    final cs = Theme.of(context).colorScheme;

    return AppDialog.show(
      context: context,
      title: title,
      icon: Icon(Icons.warning_amber_rounded, color: cs.error),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.error.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use with caution! Raw configuration overrides directly alter internal engine parameters and may cause instability or crashes if misconfigured.',
                    style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              labelText: 'Raw Configuration Strings',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onSave(controller.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save Override'),
        ),
      ],
    ).whenComplete(() => controller.dispose());
  }
}
