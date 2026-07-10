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

String? formatDateString(String? dateString) {
  if (dateString == null || dateString.trim().isEmpty) return null;
  final trimmed = dateString.trim();

  // Check if it's a numeric timestamp (e.g., "1719830400000" or "1719830400" or "1719830400.0")
  final numVal = int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
  if (numVal != null && numVal > 0) {
    int millis;
    if (numVal > 100000000000) {
      millis = numVal;
    } else if (numVal > 100000000) {
      millis = numVal * 1000;
    } else {
      return trimmed;
    }

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(millis);
      return _formatDateTime(date);
    } catch (_) {
      return trimmed;
    }
  }

  // Check if it's an ISO/standard date string that parses with DateTime.tryParse
  final parsedDate = DateTime.tryParse(trimmed);
  if (parsedDate != null) {
    return _formatDateTime(parsedDate);
  }

  return trimmed;
}

String _formatDateTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.isNegative || diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '${weeks}w ago';
  }
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }

  const monthsList = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final monthStr = (date.month >= 1 && date.month <= 12)
      ? monthsList[date.month - 1]
      : '';
  return '$monthStr ${date.day}, ${date.year}';
}

String? formatEpisodeNumber(num? value) {
  if (value == null) return null;

  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}
