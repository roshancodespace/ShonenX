import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/providers/library_view_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class LibraryFiltersWidget extends ConsumerWidget {
  const LibraryFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final viewState = ref.watch(libraryViewStateProvider);
    final radius = GlobalUI.uiRoundness.clamp(10.0, 24.0);
    final statuses = TrackedStatus.values
        .where((s) => s != TrackedStatus.unknown)
        .toList();

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        physics: const BouncingScrollPhysics(),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isActive = viewState.status == status;
          final label = status.getLocalizedLabelForMedia(
            context,
            viewState.mediaType,
          );

          return Material(
            color: isActive ? cs.primaryContainer : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: () {
                if (!isActive) {
                  ref.read(libraryViewStateProvider.notifier).setStatus(status);
                }
              },
              borderRadius: BorderRadius.circular(radius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: isActive
                        ? cs.primary.withValues(alpha: 0.45)
                        : cs.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
