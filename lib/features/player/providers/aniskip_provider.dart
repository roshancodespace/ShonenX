import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/data/aniskip_service.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';

final aniSkipServiceProvider = Provider<AniSkipService>((ref) {
  return AniSkipService();
});

class AniSkipArgs {
  final int malId;
  final int episodeNumber;
  final int episodeLength;

  const AniSkipArgs({
    required this.malId,
    required this.episodeNumber,
    required this.episodeLength,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AniSkipArgs &&
          runtimeType == other.runtimeType &&
          malId == other.malId &&
          episodeNumber == other.episodeNumber &&
          episodeLength == other.episodeLength;

  @override
  int get hashCode => Object.hash(malId, episodeNumber, episodeLength);
}

final aniSkipProvider = FutureProvider.autoDispose
    .family<List<AniSkipStamp>, AniSkipArgs?>((ref, args) async {
      if (args == null || args.episodeLength < 50) {
        return [];
      }

      ref.keepAlive();

      final prefs = ref.watch(aniskipPrefsProvider);
      final enabledTypes = prefs.enabledTypes();
      if (enabledTypes.isEmpty) {
        return [];
      }

      final service = ref.read(aniSkipServiceProvider);
      return await service.getSkipTimes(
        types: enabledTypes,
        idMal: args.malId,
        episodeNumber: args.episodeNumber,
        episodeLength: args.episodeLength,
      );
    });
