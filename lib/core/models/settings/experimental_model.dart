import 'dart:convert';

class ExperimentalFeaturesModel {
  bool episodeTitleSync;
  bool useExtensions;
  bool useTestReleases;
  bool newUI;
  bool debugMode;

  ExperimentalFeaturesModel({
    this.episodeTitleSync = false,
    this.useExtensions = false,
    this.useTestReleases = false,
    this.newUI = false,
    this.debugMode = false,
  });

  ExperimentalFeaturesModel copyWith({
    bool? episodeTitleSync,
    bool? useExtensions,
    bool? useTestReleases,
    bool? newUI,
    bool? debugMode,
  }) {
    return ExperimentalFeaturesModel(
      episodeTitleSync: episodeTitleSync ?? this.episodeTitleSync,
      useExtensions: useExtensions ?? this.useExtensions,
      useTestReleases: useTestReleases ?? this.useTestReleases,
      newUI: newUI ?? this.newUI,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'episodeTitleSync': episodeTitleSync,
      'useMangayomiExtensions': useExtensions,
      'useTestReleases': useTestReleases,
      'newUI': newUI,
      'debugMode': debugMode,
    };
  }

  factory ExperimentalFeaturesModel.fromMap(Map<String, dynamic> map) {
    return ExperimentalFeaturesModel(
      episodeTitleSync: map['episodeTitleSync'] ?? false,
      useExtensions: map['useMangayomiExtensions'] ?? false,
      useTestReleases: map['useTestReleases'] ?? false,
      newUI: map['newUI'] ?? false,
      debugMode: map['debugMode'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ExperimentalFeaturesModel.fromJson(String source) =>
      ExperimentalFeaturesModel.fromMap(json.decode(source));
}
