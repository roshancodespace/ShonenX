import 'package:flutter/material.dart';

class RawConfigOverrideSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final ValueChanged<String> onSave;
  final String hintText;

  const RawConfigOverrideSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onSave,
    this.hintText = 'e.g. key=value or property override per line',
  });

  @override
  State<RawConfigOverrideSheet> createState() => _RawConfigOverrideSheetState();
}

class _RawConfigOverrideSheetState extends State<RawConfigOverrideSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
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
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                labelText: 'Raw Configuration Strings',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_controller.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save Override'),
        ),
      ],
    );
  }
}
