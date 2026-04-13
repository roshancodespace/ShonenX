import 'package:flutter/material.dart';

class TrackerUpdateDialogs {
  static Future<String?> showStatusUpdateDialog(
    BuildContext context,
    String currentStatus,
    List<String> statuses,
  ) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Update Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...statuses.map((status) {
                  final isSelected = status == currentStatus;
                  final colorScheme = Theme.of(context).colorScheme;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      _format(status),
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    onTap: () => Navigator.pop(context, status),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<int?> showProgressUpdateDialog(
    BuildContext context,
    int currentProgress,
    int? maxEpisodes,
  ) {
    return showDialog<int>(
      context: context,
      builder: (context) => _NumberInputDialog<int>(
        title: 'Update Progress',
        label: 'Episodes watched',
        initialValue: currentProgress.toString(),
        suffixText: maxEpisodes != null ? '/ $maxEpisodes' : null,
        isDouble: false,
      ),
    );
  }

  static Future<double?> showScoreUpdateDialog(
    BuildContext context,
    double currentScore,
  ) {
    return showDialog<double>(
      context: context,
      builder: (context) => _NumberInputDialog<double>(
        title: 'Update Score',
        label: 'Score (0 - 10)',
        initialValue: currentScore.toStringAsFixed(1),
        isDouble: true,
      ),
    );
  }

  static String _format(String s) {
    final clean = s.replaceAll('_', ' ').toLowerCase();
    if (clean.isEmpty) return s;
    return clean[0].toUpperCase() + clean.substring(1);
  }
}

class _NumberInputDialog<T extends num> extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final String? suffixText;
  final bool isDouble;

  const _NumberInputDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    this.suffixText,
    required this.isDouble,
  });

  @override
  State<_NumberInputDialog<T>> createState() => _NumberInputDialogState<T>();
}

class _NumberInputDialogState<T extends num>
    extends State<_NumberInputDialog<T>> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = widget.isDouble
        ? double.tryParse(_controller.text)
        : int.tryParse(_controller.text);

    if (val != null) Navigator.pop(context, val as T);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.isDouble),
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: widget.suffixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
