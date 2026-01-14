// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThemeModelAdapter extends TypeAdapter<ThemeModel> {
  @override
  final typeId = 2;

  @override
  ThemeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeModel(
      themeMode: fields[0] == null ? 'system' : fields[0] as String,
      amoled: fields[1] == null ? false : fields[1] as bool,
      flexScheme: fields[2] as String?,
      blendLevel: fields[3] == null ? 11 : (fields[3] as num).toInt(),
      swapColors: fields[4] == null ? false : fields[4] as bool,
      useMaterial3: fields[5] == null ? true : fields[5] as bool,
      useDynamicColors: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.amoled)
      ..writeByte(2)
      ..write(obj.flexScheme)
      ..writeByte(3)
      ..write(obj.blendLevel)
      ..writeByte(4)
      ..write(obj.swapColors)
      ..writeByte(5)
      ..write(obj.useMaterial3)
      ..writeByte(6)
      ..write(obj.useDynamicColors);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
