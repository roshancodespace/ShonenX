import 'package:shonenx/core_new/eval/dart/service.dart';
import 'package:shonenx/core_new/eval/javascript/service.dart';
import 'package:shonenx/core_new/eval/model/source_preference.dart';
import 'package:shonenx/core_new/models/source.dart';

List<SourcePreference> getSourcePreference({required Source source}) {
  List<SourcePreference> sourcePreference = [];

  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    sourcePreference = DartExtensionService(source).getSourcePreferences();
  } else {
    sourcePreference = JsExtensionService(source).getSourcePreferences();
  }

  return sourcePreference;
}