import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

abstract class CardConfig {
  const CardConfig();
  Map<String, dynamic> toJson();

  static CardConfig fromJson(MediaCardStyle style, Map<String, dynamic>? json) {
    return const EmptyCardConfig();
  }
}

class EmptyCardConfig extends CardConfig {
  const EmptyCardConfig();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  bool operator ==(Object other) => other is EmptyCardConfig;

  @override
  int get hashCode => 0;
}
