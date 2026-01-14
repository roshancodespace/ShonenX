// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final typeId = 13;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.downloaded;
      case 1:
        return DownloadStatus.downloading;
      case 2:
        return DownloadStatus.paused;
      case 3:
        return DownloadStatus.error;
      case 4:
        return DownloadStatus.queued;
      case 5:
        return DownloadStatus.failed;
      default:
        return DownloadStatus.downloaded;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.downloaded:
        writer.writeByte(0);
      case DownloadStatus.downloading:
        writer.writeByte(1);
      case DownloadStatus.paused:
        writer.writeByte(2);
      case DownloadStatus.error:
        writer.writeByte(3);
      case DownloadStatus.queued:
        writer.writeByte(4);
      case DownloadStatus.failed:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
