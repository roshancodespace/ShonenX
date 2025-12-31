import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';

part 'download_item.g.dart';

@HiveType(typeId: HiveTypeIds.downloads)
class DownloadItem {
  @HiveField(0)
  final String animeTitle;
  @HiveField(1)
  final String episodeTitle;
  @HiveField(2)
  final int episodeNumber;
  @HiveField(3)
  final String thumbnail;
  @HiveField(4)
  final int? size;
  @HiveField(5)
  final DownloadStatus state;
  @HiveField(6)
  final int progress;
  @HiveField(7)
  final String downloadUrl;
  @HiveField(8)
  final String quality;
  @HiveField(9)
  final String filePath;
  @HiveField(10, defaultValue: {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  })
  final Map<dynamic, dynamic> headers;
  final int speed;
  final Duration? eta;
  final dynamic error;

  @HiveField(11)
  final String? contentType;

  @HiveField(12)
  final List<dynamic>? subtitles;

  @HiveField(13)
  final int? totalSegments;

  bool get isM3U8 =>
      contentType == 'video/MP2T' ||
      contentType == 'application/vnd.apple.mpegurl' ||
      contentType == 'application/x-mpegurl' ||
      downloadUrl.contains('.m3u8');

  bool get hasByteSize => size != null && size! > 0;
  bool get hasSegmentCount => totalSegments != null && totalSegments! > 0;
  bool get hasError => error != null;

  double get progressPercentage {
    if (hasByteSize) {
      return (progress / size!).clamp(0.0, 1.0);
    } else if (hasSegmentCount) {
      return (progress / totalSegments!).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String getProgressText() {
    if (hasByteSize) {
      final currentMB = (progress / 1024 / 1024).toStringAsFixed(1);
      final totalMB = (size! / 1024 / 1024).toStringAsFixed(1);
      return '$currentMB / $totalMB MB';
    } else if (hasSegmentCount) {
      return '$progress / $totalSegments segments';
    }
    return 'Downloading...';
  }

  DownloadItem({
    this.quality = 'Default',
    required this.downloadUrl,
    required this.animeTitle,
    required this.episodeTitle,
    required this.episodeNumber,
    required this.thumbnail,
    this.size,
    required this.state,
    required this.progress,
    required this.filePath,
    this.headers = const {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    },
    this.speed = 0,
    this.eta,
    this.contentType,
    this.error,
    this.subtitles,
    this.totalSegments,
  });

  DownloadItem copyWith({
    String? animeTitle,
    String? episodeTitle,
    int? episodeNumber,
    String? thumbnail,
    int? size,
    DownloadStatus? state,
    int? progress,
    String? filePath,
    String? downloadUrl,
    String? quality,
    Map<dynamic, dynamic>? headers,
    int? speed,
    Duration? eta,
    dynamic error,
    String? contentType,
    int? totalSegments,
  }) {
    return DownloadItem(
      animeTitle: animeTitle ?? this.animeTitle,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      thumbnail: thumbnail ?? this.thumbnail,
      size: size ?? this.size,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      quality: quality ?? this.quality,
      headers: headers ?? this.headers,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      error: error ?? this.error,
      contentType: contentType ?? this.contentType,
      totalSegments: totalSegments ?? this.totalSegments,
    );
  }

  @override
  String toString() {
    return 'DownloadItem(animeTitle: $animeTitle, episodeTitle: $episodeTitle, episodeNumber: $episodeNumber, thumbnail: $thumbnail, size: $size, state: $state, progress: $progress, downloadUrl: $downloadUrl, quality: $quality, filePath: $filePath, headers: $headers, speed: $speed, eta: $eta, contentType: $contentType, totalSegments: $totalSegments, error: $error)';
  }
}
