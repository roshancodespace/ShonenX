import '../Lnreader/service.dart';
import 'Eval/dart/service.dart';
import 'Eval/javascript/service.dart';
import 'Models/Source.dart';
import 'interface.dart';

ExtensionService getExtensionService(MSource source) {
  return switch (source.sourceCodeLanguage) {
    SourceCodeLanguage.dart => DartExtensionService(source),
    SourceCodeLanguage.javascript => JsExtensionService(source),
    SourceCodeLanguage.lnreader => LNReaderExtensionService(source),
  };
}
