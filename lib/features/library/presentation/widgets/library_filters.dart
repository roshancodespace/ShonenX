import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/providers/library_view_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';

class LibraryFiltersWidget extends ConsumerWidget {
  const LibraryFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewState = ref.watch(libraryViewStateProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: TrackedStatus.values
            .where((s) => s != TrackedStatus.unknown)
            .map((status) {
          final isActive = viewState.status == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                status.getLabelForMedia(viewState.mediaType),
                style: TextStyle(
                  color: isActive
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
              selected: isActive,
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              onSelected: (selected) {
                if (selected) {
                  ref.read(libraryViewStateProvider.notifier).setStatus(status);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
