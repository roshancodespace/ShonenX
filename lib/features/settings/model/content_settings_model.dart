import 'dart:convert';

class ContentSettingsModel {
  final bool showAnilistAdult;
  final bool showMalAdult;
  final bool smartSourceEnabled;

  const ContentSettingsModel({
    this.showAnilistAdult = false,
    this.showMalAdult = false,
    this.smartSourceEnabled = true,
  });

  ContentSettingsModel copyWith({
    bool? showAnilistAdult,
    bool? showMalAdult,
    bool? smartSourceEnabled,
  }) {
    return ContentSettingsModel(
      showAnilistAdult: showAnilistAdult ?? this.showAnilistAdult,
      showMalAdult: showMalAdult ?? this.showMalAdult,
      smartSourceEnabled: smartSourceEnabled ?? this.smartSourceEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showAnilistAdult': showAnilistAdult,
      'showMalAdult': showMalAdult,
      'smartSourceEnabled': smartSourceEnabled,
    };
  }

  factory ContentSettingsModel.fromMap(Map<String, dynamic> map) {
    return ContentSettingsModel(
      showAnilistAdult: map['showAnilistAdult'] ?? false,
      showMalAdult: map['showMalAdult'] ?? false,
      smartSourceEnabled: map['smartSourceEnabled'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ContentSettingsModel.fromJson(String source) =>
      ContentSettingsModel.fromMap(json.decode(source));
}
