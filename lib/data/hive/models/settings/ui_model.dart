import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'ui_model.g.dart';

@HiveType(typeId: HiveTypeIds.ui)
class UiSettings extends HiveObject {
  @HiveField(0)
  final bool compactMode;

  @HiveField(1)
  final String defaultTab;

  @HiveField(2)
  final bool showThumbnails;

  @HiveField(3)
  final String cardStyle;

  @HiveField(4)
  final String layoutStyle;

  @HiveField(5)
  final bool immersiveMode;

  UiSettings({
    this.compactMode = false,
    this.defaultTab = 'Home',
    this.showThumbnails = true,
    this.cardStyle = 'Card',
    this.layoutStyle = 'horizontal',
    this.immersiveMode = false,
  });

  UiSettings copyWith({
    bool? compactMode,
    String? defaultTab,
    bool? showThumbnails,
    String? cardStyle,
    String? layoutStyle,
    bool? immersiveMode,
  }) {
    return UiSettings(
      compactMode: compactMode ?? this.compactMode,
      defaultTab: defaultTab ?? this.defaultTab,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      cardStyle: cardStyle ?? this.cardStyle,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      immersiveMode: immersiveMode ?? this.immersiveMode,
    );
  }
}
