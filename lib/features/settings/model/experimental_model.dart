import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'experimental_model.g.dart';

@HiveType(typeId: HiveTypeIds.experimental)
class ExperimentalFeaturesModel {
  @HiveField(0, defaultValue: false)
  bool episodeTitleSync;
  @HiveField(1, defaultValue: false)
  bool useMangayomiExtensions;

  ExperimentalFeaturesModel(
      {this.episodeTitleSync = false, this.useMangayomiExtensions = false});

  ExperimentalFeaturesModel copyWith({
    bool? episodeTitleSync,
    bool? useMangayomiExtensions,
  }) {
    return ExperimentalFeaturesModel(
      episodeTitleSync: episodeTitleSync ?? this.episodeTitleSync,
      useMangayomiExtensions:
          useMangayomiExtensions ?? this.useMangayomiExtensions,
    );
  }
}
