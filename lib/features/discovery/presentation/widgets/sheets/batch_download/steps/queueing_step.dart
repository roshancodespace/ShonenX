import 'package:flutter/material.dart';

import '../batch_download_sheet.dart';

class QueueingStep extends StatelessWidget {
  final BatchDownloadSheetState state;

  const QueueingStep({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      key: const ValueKey('queueing'),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: state.sortedSelected.isNotEmpty
                  ? state.currentIndex / state.sortedSelected.length
                  : null,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            state.currentQueueStatus,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Resolving links and queuing tasks...',
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => state.showCancelDialog(context),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text(
              'Cancel Queueing',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: cs.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
