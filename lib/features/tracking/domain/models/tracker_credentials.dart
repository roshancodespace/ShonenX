class TrackerCredentials {
  final String clientId;
  final String clientSecret;

  const TrackerCredentials({
    required this.clientId,
    required this.clientSecret,
  });

  Map<String, dynamic> toMap() {
    return {'clientId': clientId, 'clientSecret': clientSecret};
  }

  factory TrackerCredentials.fromMap(Map<String, dynamic> map) {
    return TrackerCredentials(
      clientId: map['clientId'] ?? '',
      clientSecret: map['clientSecret'] ?? '',
    );
  }
}
