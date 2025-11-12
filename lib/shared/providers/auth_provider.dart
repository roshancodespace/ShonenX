import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/anilist/services/auth_service.dart';
import 'package:shonenx/core/myanimelist/services/auth_service.dart';

final anilistAuthServiceProvider = Provider((ref) => AniListAuthService());

final malAuthServiceProvider = Provider((ref) => MyAnimeListAuthService());
