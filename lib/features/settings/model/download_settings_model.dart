import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'download_settings_model.g.dart';

@HiveType(typeId: HiveTypeIds.downloadSettings)
class DownloadSettingsModel {
  @HiveField(0)
  final String? customDownloadPath;

  @HiveField(1)
  final bool useCustomPath;

  @HiveField(2)
  final String folderStructure;

  @HiveField(3)
  final int parallelDownloads;

  @HiveField(4)
  final int speedLimitKBps;

  @HiveField(5)
  final bool wifiOnly;

  DownloadSettingsModel({
    this.customDownloadPath,
    this.useCustomPath = false,
    this.folderStructure = 'Anime/Episode',
    this.parallelDownloads = 5,
    this.speedLimitKBps = 0,
    this.wifiOnly = false,
  });

  DownloadSettingsModel copyWith({
    String? customDownloadPath,
    bool? useCustomPath,
    String? folderStructure,
    int? parallelDownloads,
    int? speedLimitKBps,
    bool? wifiOnly,
  }) {
    return DownloadSettingsModel(
      customDownloadPath: customDownloadPath ?? this.customDownloadPath,
      useCustomPath: useCustomPath ?? this.useCustomPath,
      folderStructure: folderStructure ?? this.folderStructure,
      parallelDownloads: parallelDownloads ?? this.parallelDownloads,
      speedLimitKBps: speedLimitKBps ?? this.speedLimitKBps,
      wifiOnly: wifiOnly ?? this.wifiOnly,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customDownloadPath': customDownloadPath,
      'useCustomPath': useCustomPath,
      'folderStructure': folderStructure,
      'parallelDownloads': parallelDownloads,
      'speedLimitKBps': speedLimitKBps,
      'wifiOnly': wifiOnly,
    };
  }

  factory DownloadSettingsModel.fromMap(Map<String, dynamic> map) {
    return DownloadSettingsModel(
      customDownloadPath: map['customDownloadPath'],
      useCustomPath: map['useCustomPath'] ?? false,
      folderStructure: map['folderStructure'] ?? 'Anime/Episode',
      parallelDownloads: map['parallelDownloads']?.toInt() ?? 5,
      speedLimitKBps: map['speedLimitKBps']?.toInt() ?? 0,
      wifiOnly: map['wifiOnly'] ?? false,
    );
  }
}
