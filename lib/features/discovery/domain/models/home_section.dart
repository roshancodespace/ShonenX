import 'dart:convert';

import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/unified_media.dart';

enum HomeSectionType {
  trending,
  continueMedia,
  libraryStatus,
}

class HomeSection {
  final String id;
  final String title;
  final HomeSectionType type;
  final bool disabled;
  final TrackedStatus? libraryStatus;
  final TrackerType? targetTracker;
  final MediaType? targetMediaType;

  const HomeSection({
    required this.id,
    required this.title,
    required this.type,
    this.disabled = false,
    this.libraryStatus,
    this.targetTracker,
    this.targetMediaType,
  });

  HomeSection copyWith({
    String? id,
    String? title,
    HomeSectionType? type,
    bool? disabled,
    TrackedStatus? libraryStatus,
    TrackerType? targetTracker,
    MediaType? targetMediaType,
    bool clearTargetTracker = false,
  }) {
    return HomeSection(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      disabled: disabled ?? this.disabled,
      libraryStatus: libraryStatus ?? this.libraryStatus,
      targetTracker: clearTargetTracker
          ? null
          : (targetTracker ?? this.targetTracker),
      targetMediaType: targetMediaType ?? this.targetMediaType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'disabled': disabled,
      'libraryStatus': libraryStatus?.name,
      'targetTracker': targetTracker?.id,
      'targetMediaType': targetMediaType?.id,
    };
  }

  factory HomeSection.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String;
    var parsedType = HomeSectionType.trending;
    
    MediaType? parsedMediaType = map['targetMediaType'] != null
          ? MediaType.values.firstWhere((e) => e.id == map['targetMediaType'], orElse: () => MediaType.ANIME)
          : null;

    // Legacy Migration
    if (typeString == 'continueWatching') {
      parsedType = HomeSectionType.continueMedia;
      parsedMediaType ??= MediaType.ANIME;
    } else if (typeString == 'continueReading') {
      parsedType = HomeSectionType.continueMedia;
      parsedMediaType ??= MediaType.MANGA;
    } else if (typeString == 'cloudLibraryStatus' || typeString == 'localLibraryStatus') {
      parsedType = HomeSectionType.libraryStatus;
    } else {
      parsedType = HomeSectionType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => HomeSectionType.trending,
      );
    }

    return HomeSection(
      id: map['id'] as String,
      title: map['title'] as String,
      type: parsedType,
      disabled: map['disabled'] ?? false,
      libraryStatus: map['libraryStatus'] != null
          ? TrackedStatus.values.firstWhere(
              (e) => e.name == map['libraryStatus'],
              orElse: () => TrackedStatus.unknown,
            )
          : null,
      targetTracker: map['targetTracker'] != null
          ? TrackerType.tryFromId(map['targetTracker'])
          : null,
      targetMediaType: parsedMediaType,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HomeSection.fromJson(String source) =>
      HomeSection.fromMap(jsonDecode(source));
}
