import 'package:shonenx/core/models/universal/universal_media.dart';

class UniversalMediaListEntry {
  final String id;
  final UniversalMedia media;
  final String status;
  final double score;
  final int progress;
  final int repeat;
  final bool isPrivate;
  final String notes;

  const UniversalMediaListEntry({
    required this.id,
    required this.media,
    required this.status,
    required this.score,
    required this.progress,
    required this.repeat,
    required this.isPrivate,
    required this.notes,
  });



  UniversalMediaListEntry copyWith({
    String? id,
    UniversalMedia? media,
    String? status,
    double? score,
    int? progress,
    int? repeat,
    bool? isPrivate,
    String? notes,
  }) {
    return UniversalMediaListEntry(
      id: id ?? this.id,
      media: media ?? this.media,
      status: status ?? this.status,
      score: score ?? this.score,
      progress: progress ?? this.progress,
      repeat: repeat ?? this.repeat,
      isPrivate: isPrivate ?? this.isPrivate,
      notes: notes ?? this.notes,
    );
  }
}

