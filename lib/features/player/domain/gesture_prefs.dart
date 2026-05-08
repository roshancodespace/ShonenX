class GesturePrefs {
  final double topMargin;
  final double bottomMargin;
  final double leftMargin;
  final double rightMargin;
  final double leftWidth;
  final double rightWidth;
  final double doubleTapWidth;

  const GesturePrefs({
    this.topMargin = 0.05,
    this.bottomMargin = 0.05,
    this.leftMargin = 0.05,
    this.rightMargin = 0.05,
    this.leftWidth = 0.35,
    this.rightWidth = 0.35,
    this.doubleTapWidth = 0.35,
  });

  GesturePrefs copyWith({
    double? topMargin,
    double? bottomMargin,
    double? leftMargin,
    double? rightMargin,
    double? leftWidth,
    double? rightWidth,
    double? doubleTapWidth,
  }) {
    return GesturePrefs(
      topMargin: topMargin ?? this.topMargin,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      leftMargin: leftMargin ?? this.leftMargin,
      rightMargin: rightMargin ?? this.rightMargin,
      leftWidth: leftWidth ?? this.leftWidth,
      rightWidth: rightWidth ?? this.rightWidth,
      doubleTapWidth: doubleTapWidth ?? this.doubleTapWidth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topMargin': topMargin,
      'bottomMargin': bottomMargin,
      'leftMargin': leftMargin,
      'rightMargin': rightMargin,
      'leftWidth': leftWidth,
      'rightWidth': rightWidth,
      'doubleTapWidth': doubleTapWidth,
    };
  }

  factory GesturePrefs.fromMap(Map<String, dynamic> map) {
    return GesturePrefs(
      topMargin: (map['topMargin'] ?? 0.0).toDouble(),
      bottomMargin: (map['bottomMargin'] ?? 0.0).toDouble(),
      leftMargin: (map['leftMargin'] ?? 0.0).toDouble(),
      rightMargin: (map['rightMargin'] ?? 0.0).toDouble(),
      leftWidth: (map['leftWidth'] ?? 0.4).toDouble(),
      rightWidth: (map['rightWidth'] ?? 0.4).toDouble(),
      doubleTapWidth: (map['doubleTapWidth'] ?? 0.4).toDouble(),
    );
  }
}
