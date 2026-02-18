import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/shared/providers/mal_service_provider.dart';
import 'package:shonenx/core/repositories/anilist_repository.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';

import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';

final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  final auth = ref.watch(authProvider);

  if (auth.activePlatform == AuthPlatform.mal) {
    return ref.read(malServiceProvider);
  } else {
    return AniListRepository(ref.read(anilistServiceProvider));
  }
});
