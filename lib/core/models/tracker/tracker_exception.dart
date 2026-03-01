class TrackerException implements Exception {
  final String message;
  final dynamic error;

  TrackerException(this.message, [this.error]);

  @override
  String toString() =>
      'TrackerException: $message${error != null ? ' ($error)' : ''}';
}
