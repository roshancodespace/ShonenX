import 'package:isar_community/isar.dart';

part 'notification_subscription.g.dart';

enum SubscriptionType { animeAiring, mangaChapter, custom }

enum SubscriptionMode { nextOnly, entireSeason, targetEpisode }

@collection
class NotificationSubscription {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  @Index(
    composite: [CompositeIndex('referenceId')],
    unique: true,
    replace: true,
  )
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

  static NotificationSubscription fromBackupMap(Map<String, dynamic> m) {
    final typeName = m['type']?.toString();
    final type = SubscriptionType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => SubscriptionType.animeAiring,
    );
    final modeName = m['mode']?.toString();
    final mode = SubscriptionMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => SubscriptionMode.nextOnly,
    );

    int offset = 0;
    final rawOffset = m['offsetMinutes'];
    if (rawOffset is num) {
      offset = rawOffset.toInt();
    } else if (rawOffset is String) {
      offset = int.tryParse(rawOffset) ?? 0;
    }

    return NotificationSubscription()
      ..type = type
      ..referenceId = (m['referenceId'] ?? m['id'] ?? '')?.toString() ?? ''
      ..title =
          (m['title'] ?? m['name'] ?? 'Untitled')?.toString() ?? 'Untitled'
      ..image = (m['image'] ?? m['cover'] ?? '')?.toString() ?? ''
      ..isEnabled = m['isEnabled'] is bool ? (m['isEnabled'] as bool) : true
      ..mode = mode
      ..offsetMinutes = offset
      ..upcomingIdentifier = m['upcomingIdentifier']?.toString()
      ..upcomingTime = DateTime.tryParse(m['upcomingTime']?.toString() ?? '')
      ..createdAt =
          DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();
  }
}
