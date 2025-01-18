import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 0)
class SettingsModel extends HiveObject {
  @HiveField(0)
  ThemeModel? theme;

  SettingsModel({
    required this.theme,
  });
}

@HiveType(typeId: 1)
class ThemeModel extends HiveObject {
  @HiveField(0)
  String themeMode;
  @HiveField(1)
  FlexScheme flexScheme;
  @HiveField(2)
  bool trueBlack;
  @HiveField(3)
  bool swapColors;
  @HiveField(4)
  double cardRadius;

  ThemeModel({
    this.themeMode = 'dark',
    this.flexScheme = FlexScheme.red,
    this.trueBlack = true,
    this.swapColors = false,
    this.cardRadius = 20.0,
  }); // Default value ensures it's never null
}
