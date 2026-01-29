extension MapStringDynamicConversion on Map {
  Map<String, String> get toMapStringString {
    return map((key, value) => MapEntry(key.toString(), value.toString()));
  }
}
