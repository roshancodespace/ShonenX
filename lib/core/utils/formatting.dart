String formatCountdown(DateTime target) {
  final now = DateTime.now();

  if (target.isBefore(now)) return '0M';

  final diff = target.difference(now);

  final days = diff.inDays;
  final hours = diff.inHours % 24;
  final minutes = diff.inMinutes % 60;

  final parts = <String>[];

  if (days > 0) parts.add('${days}D');
  if (hours > 0) parts.add('${hours}H');
  if (minutes > 0) parts.add('${minutes}M');

  return parts.isEmpty ? '0M' : parts.join(' ');
}

String trimText(String? text, {int maxLength = 100, String suffix = '...'}) {
  if (text == null || text.isEmpty) return '';

  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength).trim()}$suffix';
}
