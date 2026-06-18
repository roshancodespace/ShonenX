import 'dart:convert';

import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

enum HomeSectionType {
  continueWatching,
  trending,
  popular,
  cloudLibraryStatus,
  localLibraryStatus,
}

class HomeSection {
  final String id;
  final String title;
  final HomeSectionType type;
  final bool disabled;
  final TrackedStatus? libraryStatus;
  final TrackerType? targetTracker;

  const HomeSection({
    required this.id,
    required this.title,
    required this.type,
    this.disabled = false,
    this.libraryStatus,
    this.targetTracker,
  });

  HomeSection copyWith({
    String? id,
    String? title,
    HomeSectionType? type,
    bool? disabled,
    TrackedStatus? libraryStatus,
    TrackerType? targetTracker,
    bool clearTargetTracker = false,
  }) {
    return HomeSection(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      disabled: disabled ?? this.disabled,
      libraryStatus: libraryStatus ?? this.libraryStatus,
      targetTracker: clearTargetTracker ? null : (targetTracker ?? this.targetTracker),
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
    };
  }

  factory HomeSection.fromMap(Map<String, dynamic> map) {
    return HomeSection(
      id: map['id'] as String,
      title: map['title'] as String,
      type: HomeSectionType.values.firstWhere((e) => e.name == map['type']),
      disabled: map['disabled'] ?? false,
      libraryStatus: map['libraryStatus'] != null
          ? TrackedStatus.values.firstWhere(
              (e) => e.name == map['libraryStatus'],
            )
          : null,
      targetTracker: map['targetTracker'] != null
          ? TrackerType.tryFromId(map['targetTracker'])
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HomeSection.fromJson(String source) =>
      HomeSection.fromMap(jsonDecode(source));
}
