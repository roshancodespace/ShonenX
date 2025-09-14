import 'package:hive_flutter/hive_flutter.dart';

import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'experimental_model.g.dart';

@HiveType(typeId: HiveTypeIds.experimental)
class ExperimentalFeaturesModel {
  @HiveField(0, defaultValue: false)
  bool episodeTitleSync;

  ExperimentalFeaturesModel({this.episodeTitleSync = false});

  ExperimentalFeaturesModel copyWith({
    bool? episodeTitleSync,
  }) {
    return ExperimentalFeaturesModel(
      episodeTitleSync: episodeTitleSync ?? this.episodeTitleSync,
    );
  }
}
