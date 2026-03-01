import 'package:flutter/material.dart';

class TrackerUpdateDialogs {
  static Future<String?> showStatusUpdateDialog(
    BuildContext context,
    String currentStatus,
    List<String> statuses,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return RadioListTile<String>(
                title: Text(status),
                value: status,
                groupValue: currentStatus,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static Future<int?> showProgressUpdateDialog(
    BuildContext context,
    int currentProgress,
    int? maxEpisodes,
  ) async {
    final controller = TextEditingController(text: currentProgress.toString());
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Progress'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Episodes watched',
              suffixText: maxEpisodes != null ? '/ $maxEpisodes' : null,
            ),
            autofocus: true,
            onSubmitted: (value) {
              final val = int.tryParse(value);
              if (val != null) Navigator.pop(context, val);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null) Navigator.pop(context, val);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  static Future<double?> showScoreUpdateDialog(
    BuildContext context,
    double currentScore,
  ) async {
    final controller = TextEditingController(
      text: currentScore.toStringAsFixed(1),
    );
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Score'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Score (0 - 100)'),
            autofocus: true,
            onSubmitted: (value) {
              final val = double.tryParse(value);
              if (val != null) Navigator.pop(context, val);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null) Navigator.pop(context, val);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
