enum TrackedStatus {
  watching('Watching'),
  planning('Plan to Watch'),
  completed('Completed'),
  paused('Paused'),
  dropped('Dropped'),
  unknown('Unknown');

  final String displayName;
  const TrackedStatus(this.displayName);

  String get id => name;
}
