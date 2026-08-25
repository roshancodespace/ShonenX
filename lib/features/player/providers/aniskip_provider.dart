import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/data/aniskip_resolver.dart';
import 'package:shonenx/features/player/data/aniskip_service.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

final aniSkipServiceProvider = Provider<AniSkipService>((ref) {
  return AniSkipService();
});

class AniSkipArgs {
  final UnifiedMedia? media;
  final int? idMal;
  final double episodeNumber;
  final int episodeLength;

  const AniSkipArgs({
    this.media,
    this.idMal,
    required this.episodeNumber,
    required this.episodeLength,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AniSkipArgs &&
          runtimeType == other.runtimeType &&
          idMal == other.idMal &&
          media?.id == other.media?.id &&
          episodeNumber == other.episodeNumber &&
          episodeLength == other.episodeLength;

  @override
  int get hashCode =>
      Object.hash(idMal, media?.id, episodeNumber, episodeLength);
}

final aniSkipProvider = FutureProvider.autoDispose
    .family<List<AniSkipStamp>, AniSkipArgs?>((ref, args) async {
      if (args == null ||
          args.episodeLength < 50 ||
          args.episodeNumber % 1 != 0) {
        return [];
      }

      final prefs = ref.read(aniskipPrefsProvider);
      final enabledTypes = prefs.enabledTypes();
      if (enabledTypes.isEmpty) {
        return [];
      }

      final resolver = ref.read(aniSkipResolverProvider);
      final malId = await resolver.resolveMalId(
        media: args.media,
        idMal: args.idMal,
      );

      if (malId == null) {
        return [];
      }

      final service = ref.read(aniSkipServiceProvider);
      return await service.getSkipTimes(
        types: enabledTypes,
        idMal: malId,
        episodeNumber: args.episodeNumber.toInt(),
        episodeLength: args.episodeLength,
      );
    });
