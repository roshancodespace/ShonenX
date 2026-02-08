import 'Eval/dart/model/source_preference.dart';
import 'Eval/dart/service.dart';
import 'Eval/javascript/service.dart';
import 'Models/Source.dart';

List<SourcePreference> getSourcePreference({required MSource source}) {
  List<SourcePreference> sourcePreference = [];

  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    sourcePreference = DartExtensionService(source).getSourcePreferences();
  } else {
    sourcePreference = JsExtensionService(source).getSourcePreferences();
  }

  return sourcePreference;
}
