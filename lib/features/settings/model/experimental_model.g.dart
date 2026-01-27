// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experimental_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExperimentalFeaturesModelAdapter
    extends TypeAdapter<ExperimentalFeaturesModel> {
  @override
  final typeId = 11;

  @override
  ExperimentalFeaturesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExperimentalFeaturesModel(
      episodeTitleSync: fields[0] == null ? false : fields[0] as bool,
      useMangayomiExtensions: fields[1] == null ? false : fields[1] as bool,
      useTestReleases: fields[2] == null ? false : fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExperimentalFeaturesModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.episodeTitleSync)
      ..writeByte(1)
      ..write(obj.useMangayomiExtensions)
      ..writeByte(2)
      ..write(obj.useTestReleases);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentalFeaturesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
