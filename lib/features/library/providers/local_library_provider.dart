import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/data/library_repository.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';

final localLibraryListProvider = StreamProvider.autoDispose.family<List<LibraryEntry>, TrackedStatus>(
  (ref, status) {
    final repo = ref.watch(libraryRepositoryProvider);
    return repo.watchLibrary(status: status);
  },
);

// final isInLocalLibraryListProvider = Provider.autoDispose.family<bool, String>((
//   ref,
//   providerId,
// ) {
//   final libraryState = ref.watch(localLibraryListProvider);

//   return libraryState.maybeWhen(
//     data: (entries) => entries.any((e) => e.providerId == providerId),
//     orElse: () => false,
//   );
// });
