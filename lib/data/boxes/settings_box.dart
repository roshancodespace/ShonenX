import 'package:hive/hive.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';

class SettingsBox {
  static Box<SettingsModel> getData() =>
      Hive.box<SettingsModel>('user_settings');
}
