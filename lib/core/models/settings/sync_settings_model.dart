import 'dart:convert';

class SyncSettingsModel {
  bool syncAnilist;
  bool syncMal;
  bool localSync;
  String syncMode;
  int backgroundIntervalMinutes;
  bool askBeforeSync;
  int syncPercentage;

  SyncSettingsModel({
    this.syncAnilist = true,
    this.syncMal = true,
    this.localSync = true,
    this.syncMode = 'realtime',
    this.backgroundIntervalMinutes = 15,
    this.askBeforeSync = true,
    this.syncPercentage = 80,
  });

  SyncSettingsModel copyWith({
    bool? syncAnilist,
    bool? syncMal,
    bool? localSync,
    String? syncMode,
    int? backgroundIntervalMinutes,
    bool? askBeforeSync,
    int? syncPercentage,
  }) {
    return SyncSettingsModel(
      syncAnilist: syncAnilist ?? this.syncAnilist,
      syncMal: syncMal ?? this.syncMal,
      localSync: localSync ?? this.localSync,
      syncMode: syncMode ?? this.syncMode,
      backgroundIntervalMinutes:
          backgroundIntervalMinutes ?? this.backgroundIntervalMinutes,
      askBeforeSync: askBeforeSync ?? this.askBeforeSync,
      syncPercentage: syncPercentage ?? this.syncPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'syncAnilist': syncAnilist,
      'syncMal': syncMal,
      'localSync': localSync,
      'syncMode': syncMode,
      'backgroundIntervalMinutes': backgroundIntervalMinutes,
      'askBeforeSync': askBeforeSync,
      'syncPercentage': syncPercentage,
    };
  }

  factory SyncSettingsModel.fromMap(Map<String, dynamic> map) {
    return SyncSettingsModel(
      syncAnilist: map['syncAnilist'] ?? true,
      syncMal: map['syncMal'] ?? true,
      localSync: map['localSync'] ?? true,
      syncMode: map['syncMode'] ?? 'realtime',
      backgroundIntervalMinutes: map['backgroundIntervalMinutes'] ?? 15,
      askBeforeSync: map['askBeforeSync'] ?? true,
      syncPercentage: map['syncPercentage'] ?? 80,
    );
  }

  String toJson() => json.encode(toMap());

  factory SyncSettingsModel.fromJson(String source) =>
      SyncSettingsModel.fromMap(json.decode(source));
}
