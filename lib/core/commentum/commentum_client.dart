import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/commentum/commentum_storage.dart';
import 'package:shonenx/core/utils/env.dart';

final commentumClientProvider = Provider<CommentumClient>((ref) {
  return CommentumClient(
    config: CommentumConfig(
      baseUrl: Env.COMMENTUM_API_URL,
      enableLogging: kDebugMode,
    ),
    storage: CommentumTokenStorage(),
    preferredProvider: CommentumProvider.anilist,
  );
});
