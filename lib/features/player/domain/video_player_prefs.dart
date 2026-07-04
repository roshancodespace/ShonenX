import 'dart:convert';

class VideoPlayerPrefs {
  final bool enableHardwareAcceleration;
  final Duration minBuffer;
  final Duration maxBuffer;
  final bool enableLowLatency;
  final String userAgent;
  final bool allowBackgroundPlayback;
  final bool mixWithOthers;

  const VideoPlayerPrefs({
    this.enableHardwareAcceleration = true,
    this.minBuffer = const Duration(seconds: 5),
    this.maxBuffer = const Duration(seconds: 30),
    this.enableLowLatency = false,
    this.userAgent = 'Default',
    this.allowBackgroundPlayback = false,
    this.mixWithOthers = false,
  });

  VideoPlayerPrefs copyWith({
    bool? enableHardwareAcceleration,
    Duration? minBuffer,
    Duration? maxBuffer,
    bool? enableLowLatency,
    String? userAgent,
    bool? allowBackgroundPlayback,
    bool? mixWithOthers,
  }) {
    return VideoPlayerPrefs(
      enableHardwareAcceleration:
          enableHardwareAcceleration ?? this.enableHardwareAcceleration,
      minBuffer: minBuffer ?? this.minBuffer,
      maxBuffer: maxBuffer ?? this.maxBuffer,
      enableLowLatency: enableLowLatency ?? this.enableLowLatency,
      userAgent: userAgent ?? this.userAgent,
      allowBackgroundPlayback:
          allowBackgroundPlayback ?? this.allowBackgroundPlayback,
      mixWithOthers: mixWithOthers ?? this.mixWithOthers,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is VideoPlayerPrefs &&
            other.enableHardwareAcceleration == enableHardwareAcceleration &&
            other.minBuffer == minBuffer &&
            other.maxBuffer == maxBuffer &&
            other.enableLowLatency == enableLowLatency &&
            other.userAgent == userAgent &&
            other.allowBackgroundPlayback == allowBackgroundPlayback &&
            other.mixWithOthers == mixWithOthers);
  }

  @override
  int get hashCode => Object.hash(
        enableHardwareAcceleration,
        minBuffer,
        maxBuffer,
        enableLowLatency,
        userAgent,
        allowBackgroundPlayback,
        mixWithOthers,
      );

  @override
  String toString() {
    return 'VideoPlayerPrefs('
        'hwAccel: $enableHardwareAcceleration, '
        'minBuffer: $minBuffer, '
        'maxBuffer: $maxBuffer, '
        'lowLatency: $enableLowLatency, '
        'userAgent: $userAgent, '
        'bgPlayback: $allowBackgroundPlayback, '
        'mixAudio: $mixWithOthers'
        ')';
  }

  factory VideoPlayerPrefs.fromMap(Map<String, dynamic> map) {
    return VideoPlayerPrefs(
      enableHardwareAcceleration: map['enableHardwareAcceleration'] ?? true,
      minBuffer: Duration(milliseconds: map['minBufferMs'] ?? 5000),
      maxBuffer: Duration(milliseconds: map['maxBufferMs'] ?? 30000),
      enableLowLatency: map['enableLowLatency'] ?? false,
      userAgent: map['userAgent'] ?? 'Default',
      allowBackgroundPlayback: map['allowBackgroundPlayback'] ?? false,
      mixWithOthers: map['mixWithOthers'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableHardwareAcceleration': enableHardwareAcceleration,
      'minBufferMs': minBuffer.inMilliseconds,
      'maxBufferMs': maxBuffer.inMilliseconds,
      'enableLowLatency': enableLowLatency,
      'userAgent': userAgent,
      'allowBackgroundPlayback': allowBackgroundPlayback,
      'mixWithOthers': mixWithOthers,
    };
  }

  factory VideoPlayerPrefs.fromJson(String source) =>
      VideoPlayerPrefs.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());
}
