import 'package:hive_ce/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'player_model.g.dart';

@HiveType(typeId: HiveTypeIds.player)
class PlayerModel {
  @HiveField(0, defaultValue: 'Auto')
  final String defaultQuality;

  @HiveField(1, defaultValue: true)
  final bool enableAniSkip;

  @HiveField(2, defaultValue: false)
  final bool enableAutoSkip;

  @HiveField(3, defaultValue: false)
  final bool preferDub;

  PlayerModel({
    this.defaultQuality = 'Auto',
    this.enableAniSkip = true,
    this.enableAutoSkip = false,
    this.preferDub = false,
  });

  PlayerModel copyWith({
    String? defaultQuality,
    bool? enableAniSkip,
    bool? enableAutoSkip,
    bool? preferDub,
  }) {
    return PlayerModel(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      enableAniSkip: enableAniSkip ?? this.enableAniSkip,
      enableAutoSkip: enableAutoSkip ?? this.enableAutoSkip,
      preferDub: preferDub ?? this.preferDub,
    );
  }
}
