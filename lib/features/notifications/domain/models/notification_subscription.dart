import 'package:isar_community/isar.dart';

part 'notification_subscription.g.dart';

enum SubscriptionType {
  animeAiring,
  mangaChapter,
  custom,
}

enum SubscriptionMode {
  nextOnly,
  entireSeason,
  targetEpisode,
}

@collection
class NotificationSubscription {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  @Index(composite: [CompositeIndex('referenceId')], unique: true, replace: true)
  late SubscriptionType type;

  late String referenceId; // e.g., the anime or manga ID

  late String title;
  late String image;

  bool isEnabled = true;

  @Enumerated(EnumType.name)
  late SubscriptionMode mode;
  int offsetMinutes = 0;

  // Upcoming scheduling info
  String? upcomingIdentifier; // e.g., 'ep_5' or 'ch_10'
  DateTime? upcomingTime;

  DateTime createdAt = DateTime.now();

  Map<String, dynamic> toBackupMap() => {
        'type': type.name,
        'referenceId': referenceId,
        'title': title,
        'image': image,
        'isEnabled': isEnabled,
        'mode': mode.name,
        'offsetMinutes': offsetMinutes,
        'upcomingIdentifier': upcomingIdentifier,
        'upcomingTime': upcomingTime?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  static NotificationSubscription fromBackupMap(Map<String, dynamic> m) =>
      NotificationSubscription()
        ..type = SubscriptionType.values.firstWhere((e) => e.name == m['type'], orElse: () => SubscriptionType.animeAiring)
        ..referenceId = m['referenceId'] as String
        ..title = m['title'] as String
        ..image = m['image'] as String
        ..isEnabled = m['isEnabled'] as bool? ?? true
        ..mode = SubscriptionMode.values.firstWhere((e) => e.name == m['mode'], orElse: () => SubscriptionMode.nextOnly)
        ..offsetMinutes = m['offsetMinutes'] as int? ?? 0
        ..upcomingIdentifier = m['upcomingIdentifier'] as String?
        ..upcomingTime = m['upcomingTime'] != null
            ? DateTime.tryParse(m['upcomingTime'] as String)
            : null
        ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now();
}
