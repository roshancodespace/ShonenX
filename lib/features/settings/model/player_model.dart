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

  @HiveField(4, defaultValue: 10)
  final int seekDuration;

  @HiveField(5, defaultValue: 4)
  final int autoHideDuration;

  @HiveField(6, defaultValue: true)
  final bool showNextPrevButtons;

  PlayerModel({
    this.defaultQuality = 'Auto',
    this.enableAniSkip = true,
    this.enableAutoSkip = false,
    this.preferDub = false,
    this.seekDuration = 10,
    this.autoHideDuration = 4,
    this.showNextPrevButtons = true,
  });

  PlayerModel copyWith({
    String? defaultQuality,
    bool? enableAniSkip,
    bool? enableAutoSkip,
    bool? preferDub,
    int? seekDuration,
    int? autoHideDuration,
    bool? showNextPrevButtons,
  }) {
    return PlayerModel(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      enableAniSkip: enableAniSkip ?? this.enableAniSkip,
      enableAutoSkip: enableAutoSkip ?? this.enableAutoSkip,
      preferDub: preferDub ?? this.preferDub,
      seekDuration: seekDuration ?? this.seekDuration,
      autoHideDuration: autoHideDuration ?? this.autoHideDuration,
      showNextPrevButtons: showNextPrevButtons ?? this.showNextPrevButtons,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultQuality': defaultQuality,
      'enableAniSkip': enableAniSkip,
      'enableAutoSkip': enableAutoSkip,
      'preferDub': preferDub,
      'seekDuration': seekDuration,
      'autoHideDuration': autoHideDuration,
      'showNextPrevButtons': showNextPrevButtons,
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      defaultQuality: map['defaultQuality'] ?? 'Auto',
      enableAniSkip: map['enableAniSkip'] ?? true,
      enableAutoSkip: map['enableAutoSkip'] ?? false,
      preferDub: map['preferDub'] ?? false,
      seekDuration: map['seekDuration'] ?? 10,
      autoHideDuration: map['autoHideDuration'] ?? 4,
      showNextPrevButtons: map['showNextPrevButtons'] ?? true,
    );
  }
}
