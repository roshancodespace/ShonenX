import 'package:shonenx/core_mangayomi/eval/dart/service.dart';
import 'package:shonenx/core_mangayomi/eval/javascript/service.dart';
import 'package:shonenx/core_mangayomi/eval/model/source_preference.dart';
import 'package:shonenx/core_mangayomi/models/source.dart';

List<SourcePreference> getSourcePreference({required Source source}) {
  List<SourcePreference> sourcePreference = [];

  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    sourcePreference = DartExtensionService(source).getSourcePreferences();
  } else {
    sourcePreference = JsExtensionService(source).getSourcePreferences();
  }

  return sourcePreference;
}