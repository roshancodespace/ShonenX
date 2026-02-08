import 'dart:io';

import 'package:dartotsu_extension_bridge/Settings/Settings.dart';
import 'package:get/get.dart';

import 'Extensions/Extensions.dart';
import 'Extensions/SourceMethods.dart';
import 'Models/Source.dart';
import 'Services/Aniyomi/AniyomiExtensions.dart';
import 'Services/Aniyomi/AniyomiSourceMethods.dart';
import 'Services/Mangayomi/MangayomiExtensions.dart';
import 'Services/Mangayomi/MangayomiSourceMethods.dart';
import 'extension_bridge.dart';

class ExtensionManager extends GetxController {
  ExtensionManager() {
    initialize();
  }

  late final Rx<Extension> _currentManager;

  Extension get currentManager => _currentManager.value;

  void initialize() {
    final settings = isar.bridgeSettings.getSync(26)!;
    final savedType = ExtensionType.fromString(settings.currentManager);
    _currentManager = savedType.getManager().obs;
  }

  void setCurrentManager(ExtensionType type) {
    _currentManager.value = type.getManager();
    final settings = isar.bridgeSettings.getSync(26)!;
    isar.writeTxnSync(() {
      isar.bridgeSettings.putSync(settings..currentManager = type.toString());
    });
  }
}

abstract class HasSourceMethods {
  SourceMethods get methods;
}

extension SourceMethodsExtension on Source {
  SourceMethods get methods => currentSourceMethods(this);
}

SourceMethods currentSourceMethods(Source source) {
  if (source is HasSourceMethods) return source.methods;

  final type = source.extensionType;
  return type == ExtensionType.mangayomi
      ? MangayomiSourceMethods(source)
      : AniyomiSourceMethods(source);
}

List<ExtensionType> get getSupportedExtensions =>
    Platform.isAndroid ? ExtensionType.values : [ExtensionType.mangayomi];

enum ExtensionType {
  mangayomi,
  aniyomi;

  Extension getManager() {
    switch (this) {
      case ExtensionType.aniyomi:
        return Get.find<AniyomiExtensions>(tag: 'AniyomiExtensions');
      case ExtensionType.mangayomi:
        return Get.find<MangayomiExtensions>(tag: 'MangayomiExtensions');
    }
  }

  @override
  String toString() {
    switch (this) {
      case ExtensionType.aniyomi:
        return 'Aniyomi';
      case ExtensionType.mangayomi:
        return 'Mangayomi';
    }
  }

  static ExtensionType fromString(String? name) {
    return ExtensionType.values.firstWhere(
      (e) => e.toString() == name,
      orElse: () => getSupportedExtensions.first,
    );
  }

  static ExtensionType fromManager(Extension manager) {
    if (manager is AniyomiExtensions) {
      return ExtensionType.aniyomi;
    } else if (manager is MangayomiExtensions) {
      return ExtensionType.mangayomi;
    }
    throw Exception('Unknown extension manager type');
  }
}
