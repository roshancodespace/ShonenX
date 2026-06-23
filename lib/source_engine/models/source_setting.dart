enum SettingType { text, boolean, select, multiSelect }

class SourceSetting {
  final String id;
  final String name;
  final String description;
  final SettingType type;
  final dynamic defaultValue;
  final List<String>? options;

  const SourceSetting({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.defaultValue,
    this.options,
  });

  bool get isText => type == SettingType.text;
  bool get isBoolean => type == SettingType.boolean;
  bool get isSelect => type == SettingType.select;
  bool get isMultiSelect => type == SettingType.multiSelect;
}
