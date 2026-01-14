// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HomePageModelAdapter extends TypeAdapter<HomePageModel> {
  @override
  final typeId = 5;

  @override
  HomePageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomePageModel(
      sections: (fields[0] as Map).map(
        (dynamic k, dynamic v) => MapEntry(
          k as String,
          (v as List).map((e) => (e as Map).cast<String, dynamic>()).toList(),
        ),
      ),
      lastUpdated: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HomePageModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.sections)
      ..writeByte(1)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
