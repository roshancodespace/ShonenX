String getGreeting() {
  final now = DateTime.now();
  final hour = now.hour;

  if (hour < 12) {
    return 'Good morning';
  } else if (hour < 17) {
    return 'Good afternoon';
  } else {
    return 'Good evening';
  }
}