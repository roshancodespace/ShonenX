import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'player_model.g.dart';

@HiveType(typeId: HiveTypeIds.player)
class PlayerModel {
  @HiveField(0, defaultValue: 'Auto')
  final String defaultQuality;

  PlayerModel({
    this.defaultQuality = 'Auto',
  });

  PlayerModel copyWith({
    String? defaultQuality,
  }) {
    return PlayerModel(
      defaultQuality: defaultQuality ?? this.defaultQuality,
    );
  }
}
