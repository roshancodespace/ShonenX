import 'dart:convert';

class ContentSettingsModel {
  final bool showAnilistAdult;
  final bool showMalAdult;

  const ContentSettingsModel({
    this.showAnilistAdult = false,
    this.showMalAdult = false,
  });

  ContentSettingsModel copyWith({bool? showAnilistAdult, bool? showMalAdult}) {
    return ContentSettingsModel(
      showAnilistAdult: showAnilistAdult ?? this.showAnilistAdult,
      showMalAdult: showMalAdult ?? this.showMalAdult,
    );
  }

  Map<String, dynamic> toMap() {
    return {'showAnilistAdult': showAnilistAdult, 'showMalAdult': showMalAdult};
  }

  factory ContentSettingsModel.fromMap(Map<String, dynamic> map) {
    return ContentSettingsModel(
      showAnilistAdult: map['showAnilistAdult'] ?? false,
      showMalAdult: map['showMalAdult'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ContentSettingsModel.fromJson(String source) =>
      ContentSettingsModel.fromMap(json.decode(source));
}
