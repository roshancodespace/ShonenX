import 'package:isar_community/isar.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/core_new/models/source.dart';

Source? getSource(String lang, String name) {
  try {
    final sourcesList = isar.sources.filter().idIsNotNull().findAllSync();
    return sourcesList.lastWhere(
      (element) =>
          element.name!.toLowerCase() == name.toLowerCase() &&
          element.lang == lang &&
          element.sourceCode != null,
      orElse: () => throw ("Error when getting source"),
    );
  } catch (_) {
    return null;
  }
}
