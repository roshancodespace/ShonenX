import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'experimental_model.g.dart';

@HiveType(typeId: HiveTypeIds.experimental)
class ExperimentalFeaturesModel {
  @HiveField(0, defaultValue: false)
  bool episodeTitleSync;
  @HiveField(1, defaultValue: false)
  bool useMangayomiExtensions;
  @HiveField(2, defaultValue: false)
  bool useTestReleases;
  @HiveField(3, defaultValue: false)
  bool newUI;
  @HiveField(4, defaultValue: false)
  bool debugMode;

  ExperimentalFeaturesModel({
    this.episodeTitleSync = false,
    this.useMangayomiExtensions = false,
    this.useTestReleases = false,
    this.newUI = false,
    this.debugMode = false,
  });

  ExperimentalFeaturesModel copyWith({
    bool? episodeTitleSync,
    bool? useMangayomiExtensions,
    bool? useTestReleases,
    bool? newUI,
    bool? debugMode,
  }) {
    return ExperimentalFeaturesModel(
      episodeTitleSync: episodeTitleSync ?? this.episodeTitleSync,
      useMangayomiExtensions:
          useMangayomiExtensions ?? this.useMangayomiExtensions,
      useTestReleases: useTestReleases ?? this.useTestReleases,
      newUI: newUI ?? this.newUI,
      debugMode: debugMode ?? this.debugMode,
    );
  }
}
