import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/anilist/auth_service.dart';
import 'package:shonenx/core/services/myanimelist/auth_service.dart';

final anilistAuthServiceProvider = Provider((ref) => AniListAuthService());

final malAuthServiceProvider = Provider((ref) => MyAnimeListAuthService());
