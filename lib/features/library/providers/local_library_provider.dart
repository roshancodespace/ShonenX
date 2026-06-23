import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/data/library_repository.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/shared/models/unified_media.dart';

typedef LocalLibraryParams = ({TrackedStatus status, MediaType mediaType});

final localLibraryListProvider = StreamProvider.autoDispose.family<List<LibraryEntry>, LocalLibraryParams>(
  (ref, params) {
    final repo = ref.watch(libraryRepositoryProvider);
    return repo.watchLibrary(status: params.status, mediaType: params.mediaType);
  },
);