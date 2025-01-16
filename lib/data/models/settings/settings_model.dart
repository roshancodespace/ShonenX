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
  String themeMode; // Changed from String? to String
  @HiveField(1)
  FlexScheme flexScheme;

  ThemeModel({
    this.themeMode = 'dark',
    this.flexScheme = FlexScheme.red,
  }); // Default value ensures it's never null
}
