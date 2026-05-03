import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/data/aniskip_service.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';

class AniSkipArgs {
  final int? idMal;
  final double episodeNumber;
  final int episodeLength;

  const AniSkipArgs({
    required this.idMal,
    required this.episodeNumber,
    required this.episodeLength,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AniSkipArgs &&
          runtimeType == other.runtimeType &&
          idMal == other.idMal &&
          episodeNumber == other.episodeNumber &&
          episodeLength == other.episodeLength;

  @override
  int get hashCode =>
      idMal.hashCode ^ episodeNumber.hashCode ^ episodeLength.hashCode;
}

final aniSkipProvider = FutureProvider.autoDispose
    .family<List<AniSkipStamp>, AniSkipArgs?>((ref, args) async {
      final service = AniSkipService();
      if (args == null) {
        return [];
      } else if (args.idMal == null) {
        throw Exception('idMal is null');
      } else if (!args.episodeNumber.toString().contains('.0')) {
        throw Exception('episodeNumber is in floating');
      } else {
        return await service.getSkipTimes(
          idMal: args.idMal!,
          episodeNumber: args.episodeNumber.toInt(),
          episodeLength: args.episodeLength,
        );
      }
    });
