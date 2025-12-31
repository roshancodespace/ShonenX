// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadSettingsModelAdapter extends TypeAdapter<DownloadSettingsModel> {
  @override
  final int typeId = 14;

  @override
  DownloadSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadSettingsModel(
      customDownloadPath: fields[0] as String?,
      useCustomPath: fields[1] as bool,
      folderStructure: fields[2] as String,
      parallelDownloads: fields[3] as int,
      speedLimitKBps: fields[4] as int,
      wifiOnly: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadSettingsModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.customDownloadPath)
      ..writeByte(1)
      ..write(obj.useCustomPath)
      ..writeByte(2)
      ..write(obj.folderStructure)
      ..writeByte(3)
      ..write(obj.parallelDownloads)
      ..writeByte(4)
      ..write(obj.speedLimitKBps)
      ..writeByte(5)
      ..write(obj.wifiOnly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
