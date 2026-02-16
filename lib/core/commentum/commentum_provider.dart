import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shonenx/core/commentum/commentum_storage.dart';
import 'package:shonenx/core/utils/env_loader.dart';

final commentumClient = CommentumClient(
  config: CommentumConfig(
    baseUrl: COMMENTUM_API_URL,
    enableLogging: kDebugMode,
    verboseLogging: kDebugMode,
  ),
  storage: CommentumTokenStorage(),
);
