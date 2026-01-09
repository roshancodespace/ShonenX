import 'package:hive_ce/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'content_settings_model.g.dart';

@HiveType(typeId: HiveTypeIds.contentSettings)
class ContentSettingsModel {
  @HiveField(0, defaultValue: false)
  final bool showAnilistAdult;

  @HiveField(1, defaultValue: false)
  final bool showMalAdult;

  const ContentSettingsModel({
    this.showAnilistAdult = false,
    this.showMalAdult = false,
  });

  ContentSettingsModel copyWith({
    bool? showAnilistAdult,
    bool? showMalAdult,
  }) {
    return ContentSettingsModel(
      showAnilistAdult: showAnilistAdult ?? this.showAnilistAdult,
      showMalAdult: showMalAdult ?? this.showMalAdult,
    );
  }
}
