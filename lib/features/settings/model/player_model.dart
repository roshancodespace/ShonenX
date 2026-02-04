import 'dart:convert';

class PlayerModel {
  final String defaultQuality;
  final bool enableAniSkip;
  final bool enableAutoSkip;
  final bool preferDub;
  final int seekDuration;
  final int autoHideDuration;
  final bool showNextPrevButtons;
  final Map<String, String> mpvSettings;

  PlayerModel({
    this.defaultQuality = 'Auto',
    this.enableAniSkip = true,
    this.enableAutoSkip = false,
    this.preferDub = false,
    this.seekDuration = 10,
    this.autoHideDuration = 4,
    this.showNextPrevButtons = true,
    this.mpvSettings = const {},
  });

  PlayerModel copyWith({
    String? defaultQuality,
    bool? enableAniSkip,
    bool? enableAutoSkip,
    bool? preferDub,
    int? seekDuration,
    int? autoHideDuration,
    bool? showNextPrevButtons,
    Map<String, String>? mpvSettings,
  }) {
    return PlayerModel(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      enableAniSkip: enableAniSkip ?? this.enableAniSkip,
      enableAutoSkip: enableAutoSkip ?? this.enableAutoSkip,
      preferDub: preferDub ?? this.preferDub,
      seekDuration: seekDuration ?? this.seekDuration,
      autoHideDuration: autoHideDuration ?? this.autoHideDuration,
      showNextPrevButtons: showNextPrevButtons ?? this.showNextPrevButtons,
      mpvSettings: mpvSettings ?? this.mpvSettings,
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
      'mpvSettings': mpvSettings,
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
      mpvSettings: Map<String, String>.from(map['mpvSettings'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory PlayerModel.fromJson(String source) =>
      PlayerModel.fromMap(json.decode(source));
}
