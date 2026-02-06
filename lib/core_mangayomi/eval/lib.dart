import 'package:shonenx/core_mangayomi/eval/interface.dart';
import 'package:shonenx/core_mangayomi/models/source.dart';

import 'dart/service.dart';
import 'javascript/service.dart';

import 'package:shonenx/core/anilist/services/anilist_service.dart';

ExtensionService getExtensionService(
  Source source, {
  AnilistService? anilistService,
}) {
  return switch (source.sourceCodeLanguage) {
    SourceCodeLanguage.dart => DartExtensionService(source),
    SourceCodeLanguage.javascript => JsExtensionService(
      source,
      anilistService: anilistService,
    ),
  };
}
