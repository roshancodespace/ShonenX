// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'universal_news.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UniversalNewsAdapter extends TypeAdapter<UniversalNews> {
  @override
  final typeId = 16;

  @override
  UniversalNews read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UniversalNews(
      title: fields[0] as String?,
      url: fields[1] as String?,
      imageUrl: fields[2] as String?,
      date: fields[3] as String?,
      excerpt: fields[4] as String?,
      body: fields[5] as String?,
      isRead: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UniversalNews obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.excerpt)
      ..writeByte(5)
      ..write(obj.body)
      ..writeByte(6)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalNewsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
