// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadItemAdapter extends TypeAdapter<DownloadItem> {
  @override
  final typeId = 12;

  @override
  DownloadItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadItem(
      quality: fields[8] == null ? 'Default' : fields[8] as String,
      downloadUrl: fields[7] as String,
      animeTitle: fields[0] as String,
      episodeTitle: fields[1] as String,
      episodeNumber: (fields[2] as num).toInt(),
      thumbnail: fields[3] as String,
      size: (fields[4] as num?)?.toInt(),
      state: fields[5] as DownloadStatus,
      progress: (fields[6] as num).toInt(),
      filePath: fields[9] as String,
      headers: fields[10] == null
          ? {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            }
          : (fields[10] as Map).cast<dynamic, dynamic>(),
      contentType: fields[11] as String?,
      subtitles: (fields[12] as List?)?.cast<dynamic>(),
      totalSegments: (fields[13] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DownloadItem obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.animeTitle)
      ..writeByte(1)
      ..write(obj.episodeTitle)
      ..writeByte(2)
      ..write(obj.episodeNumber)
      ..writeByte(3)
      ..write(obj.thumbnail)
      ..writeByte(4)
      ..write(obj.size)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.progress)
      ..writeByte(7)
      ..write(obj.downloadUrl)
      ..writeByte(8)
      ..write(obj.quality)
      ..writeByte(9)
      ..write(obj.filePath)
      ..writeByte(10)
      ..write(obj.headers)
      ..writeByte(11)
      ..write(obj.contentType)
      ..writeByte(12)
      ..write(obj.subtitles)
      ..writeByte(13)
      ..write(obj.totalSegments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
