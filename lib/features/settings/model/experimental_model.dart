class ExperimentalFeaturesModel {
  bool episodeTitleSync;
  bool useMangayomiExtensions;
  bool useTestReleases;
  bool newUI;
  bool debugMode;

  ExperimentalFeaturesModel({
    this.episodeTitleSync = false,
    this.useMangayomiExtensions = false,
    this.useTestReleases = false,
    this.newUI = false,
    this.debugMode = false,
  });

  ExperimentalFeaturesModel copyWith({
    bool? episodeTitleSync,
    bool? useMangayomiExtensions,
    bool? useTestReleases,
    bool? newUI,
    bool? debugMode,
  }) {
    return ExperimentalFeaturesModel(
      episodeTitleSync: episodeTitleSync ?? this.episodeTitleSync,
      useMangayomiExtensions:
          useMangayomiExtensions ?? this.useMangayomiExtensions,
      useTestReleases: useTestReleases ?? this.useTestReleases,
      newUI: newUI ?? this.newUI,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'episodeTitleSync': episodeTitleSync,
      'useMangayomiExtensions': useMangayomiExtensions,
      'useTestReleases': useTestReleases,
      'newUI': newUI,
      'debugMode': debugMode,
    };
  }

  factory ExperimentalFeaturesModel.fromMap(Map<String, dynamic> map) {
    return ExperimentalFeaturesModel(
      episodeTitleSync: map['episodeTitleSync'] ?? false,
      useMangayomiExtensions: map['useMangayomiExtensions'] ?? false,
      useTestReleases: map['useTestReleases'] ?? false,
      newUI: map['newUI'] ?? false,
      debugMode: map['debugMode'] ?? false,
    );
  }
}
