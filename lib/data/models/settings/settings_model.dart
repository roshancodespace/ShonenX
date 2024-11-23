import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 0)
class SettingsModel extends HiveObject {
  @HiveField(0)
  String? defaultQuality;
  @HiveField(1)
  String? theme;
  @HiveField(2)
  String? defaultOrientation;
  @HiveField(3)
  String? layoutMode;
  @HiveField(4)
  bool? isLabelEnabled;

  SettingsModel({
    this.defaultQuality = '720p',
    this.theme = 'light',
    this.defaultOrientation = 'Portrait',
    this.layoutMode = 'Grid',
    this.isLabelEnabled = true,
  });

  // Factory method to create a SettingsModel object from JSON
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      defaultQuality: json['defaultQuality'] as String?,
      theme: json['theme'] as String?,
      defaultOrientation: json['defaultOrientation'] as String?,
      layoutMode: json['layoutMode'] as String?,
      isLabelEnabled: json['isLabelEnabled'] as bool?,
    );
  }

  // Method to convert a SettingsModel object to JSON
  Map<String, dynamic> toJson() {
    return {
      'defaultQuality': defaultQuality,
      'theme': theme,
      'defaultOrientation': defaultOrientation,
      'layoutMode': layoutMode,
      'isLabelEnabled': isLabelEnabled,
    };
  }

  // CopyWith method for partial updates
  SettingsModel copyWith({
    String? defaultQuality,
    String? theme,
    String? defaultOrientation,
    String? layoutMode,
    bool? isLabelEnabled,
  }) {
    return SettingsModel(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      theme: theme ?? this.theme,
      defaultOrientation: defaultOrientation ?? this.defaultOrientation,
      layoutMode: layoutMode ?? this.layoutMode,
      isLabelEnabled: isLabelEnabled ?? this.isLabelEnabled,
    );
  }
}
