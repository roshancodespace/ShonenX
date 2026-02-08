class SourcePreference {
  int? id;
  String? key;
  String? type;
  CheckBoxPreference? checkBoxPreference;
  SwitchPreferenceCompat? switchPreferenceCompat;
  ListPreference? listPreference;
  MultiSelectListPreference? multiSelectListPreference;
  EditTextPreference? editTextPreference;

  SourcePreference({
    this.id,
    this.key,
    this.type,
    this.checkBoxPreference,
    this.switchPreferenceCompat,
    this.listPreference,
    this.multiSelectListPreference,
    this.editTextPreference,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'key': key,
    'id': id,
    if (checkBoxPreference != null)
      'checkBoxPreference': checkBoxPreference!.toJson(),
    if (switchPreferenceCompat != null)
      'switchPreferenceCompat': switchPreferenceCompat!.toJson(),
    if (listPreference != null) 'listPreference': listPreference!.toJson(),
    if (multiSelectListPreference != null)
      'multiSelectListPreference': multiSelectListPreference!.toJson(),
    if (editTextPreference != null)
      'editTextPreference': editTextPreference!.toJson(),
  };

  factory SourcePreference.fromJson(Map<String, dynamic> json) {
    return SourcePreference(
      key: json['key'],
      type: json['type'],
      id: json['id'],
      checkBoxPreference: json['checkBoxPreference'] != null
          ? CheckBoxPreference.fromJson(json['checkBoxPreference'])
          : null,
      switchPreferenceCompat: json['switchPreferenceCompat'] != null
          ? SwitchPreferenceCompat.fromJson(json['switchPreferenceCompat'])
          : null,
      listPreference: json['listPreference'] != null
          ? ListPreference.fromJson(json['listPreference'])
          : null,
      multiSelectListPreference: json['multiSelectListPreference'] != null
          ? MultiSelectListPreference.fromJson(
              json['multiSelectListPreference'],
            )
          : null,
      editTextPreference: json['editTextPreference'] != null
          ? EditTextPreference.fromJson(json['editTextPreference'])
          : null,
    );
  }
}

class CheckBoxPreference {
  String? title;
  String? summary;
  bool? value;

  CheckBoxPreference({this.title, this.summary, this.value});

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'value': value,
  };

  factory CheckBoxPreference.fromJson(Map<String, dynamic> json) {
    return CheckBoxPreference(
      title: json['title'],
      summary: json['summary'],
      value: json['value'],
    );
  }
}

class SwitchPreferenceCompat {
  String? title;
  String? summary;
  bool? value;

  SwitchPreferenceCompat({this.title, this.summary, this.value});

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'value': value,
  };

  factory SwitchPreferenceCompat.fromJson(Map<String, dynamic> json) {
    return SwitchPreferenceCompat(
      title: json['title'],
      summary: json['summary'],
      value: json['value'],
    );
  }
}

class ListPreference {
  String? title;
  String? summary;
  int? valueIndex;
  List<String>? entries;
  List<String>? entryValues;

  ListPreference({
    this.title,
    this.summary,
    this.valueIndex,
    this.entries,
    this.entryValues,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'valueIndex': valueIndex,
    'entries': entries,
    'entryValues': entryValues,
  };

  factory ListPreference.fromJson(Map<String, dynamic> json) {
    return ListPreference(
      title: json['title'],
      summary: json['summary'],
      valueIndex: json['valueIndex'],
      entries: json['entries']?.cast<String>(),
      entryValues: json['entryValues']?.cast<String>(),
    );
  }
}

class MultiSelectListPreference {
  String? title;
  String? summary;
  List<String>? entries;
  List<String>? entryValues;
  List<String>? values;

  MultiSelectListPreference({
    this.title,
    this.summary,
    this.entries,
    this.entryValues,
    this.values,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'entries': entries?.cast<String>(),
    'entryValues': entryValues?.cast<String>(),
    'values': values?.cast<String>(),
  };

  factory MultiSelectListPreference.fromJson(Map<String, dynamic> json) {
    return MultiSelectListPreference(
      title: json['title'],
      summary: json['summary'],
      entries: json['entries']?.cast<String>(),
      entryValues: json['entryValues']?.cast<String>(),
      values: json['values']?.cast<String>(),
    );
  }
}

class EditTextPreference {
  String? title;
  String? summary;
  String? value;
  String? dialogTitle;
  String? dialogMessage;
  String? text;

  EditTextPreference({
    this.title,
    this.summary,
    this.value,
    this.dialogTitle,
    this.dialogMessage,
    this.text,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'value': value,
    'dialogTitle': dialogTitle,
    'dialogMessage': dialogMessage,
    'text': text,
  };

  factory EditTextPreference.fromJson(Map<String, dynamic> json) {
    return EditTextPreference(
      title: json['title'],
      summary: json['summary'],
      value: json['value'],
      dialogTitle: json['dialogTitle'],
      dialogMessage: json['dialogMessage'],
      text: json['text'],
    );
  }
}
