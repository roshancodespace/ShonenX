class StreamCleaner {
  static final RegExp _sizeRegex = RegExp(
    r'\[?\(?(\d+(?:\.\d+)?\s*(?:GB|MB|GiB|MiB|KB|kb|mb|gb))\)?\]?',
    caseSensitive: false,
  );

  static final RegExp _domainRegex = RegExp(
    r'(\b[a-zA-Z0-9_\-]+\.(?:com|org|net|tw|site|xyz|info|tv|to|is|ru|me|top|vip|pro|cc|in|co)\b)|(-[0-9]*[a-zA-Z0-9_\-]+\.[a-zA-Z]{2,4})',
    caseSensitive: false,
  );

  static final RegExp _extRegex = RegExp(
    r'\.(mkv|mp4|avi|ts|m3u8|webm|mov|flv)$',
    caseSensitive: false,
  );

  static final RegExp _releaseTagsRegex = RegExp(
    r'\b(WEB-DL|WEBRip|BluRay|BRRip|HDRip|HDTV|DVDRip|REMUX|PROPER|REPACK|SDR|NF|AMZN|DSNP|HULU|ATVP|MAX|iT)\b',
    caseSensitive: false,
  );

  static final RegExp _codecRegex = RegExp(
    r'\b(H\.?265|HEVC|x265|H\.?264|x264|AV1|10bit|HDR|Dolby\s*Vision|DV)\b',
    caseSensitive: false,
  );

  static final RegExp _audioRegex = RegExp(
    r'\b(DDP\s*5\.1|DD\s*5\.1|Atmos|TrueHD|5\.1|7\.1|Dual[\s\-]Audio|Multi[\s\-]Audio|AAC(?:\s*2\.0)?)\b',
    caseSensitive: false,
  );

  /// Extracts clean standardized resolution (e.g. '4K', '1440p', '1080p', '720p', '480p', '360p', '240p', or 'Auto').
  static String extractResolution(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Auto';
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'auto') return 'Auto';

    // Direct matches
    if (lower == '4k' || lower == '2160p' || lower == '2160') return '4K';
    if (lower == '1440p' || lower == '1440' || lower == '2k') return '1440p';
    if (lower == '1080p' || lower == '1080' || lower == 'fhd') return '1080p';
    if (lower == '720p' || lower == '720' || lower == 'hd') return '720p';
    if (lower == '480p' || lower == '480' || lower == 'sd') return '480p';
    if (lower == '360p' || lower == '360') return '360p';
    if (lower == '240p' || lower == '240') return '240p';

    // Check inside brackets/parentheses first: e.g. (4K), [1080p], (2160p)
    final bracketMatch = RegExp(
      r'[\(\[]\s*(4k|2160p?|uhd|2k|1440p?|qhd|1080p?|fhd|720p?|hd|480p?|sd|360p?|240p?)\s*[\)\]]',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (bracketMatch != null) {
      final res = _normalizeResolutionWord(bracketMatch.group(1)!);
      if (res != null) return res;
    }

    // Word boundary matches
    final wordMatch = RegExp(
      r'\b(4k|2160p?|uhd|2k|1440p?|qhd|1080p?|fhd|720p?|hd|480p?|sd|360p?|240p?)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (wordMatch != null) {
      final res = _normalizeResolutionWord(wordMatch.group(1)!);
      if (res != null) return res;
    }

    // Embedded numeric pattern e.g. .2160p. or -1080p-
    final numMatch = RegExp(r'[\._\-](\d{3,4})p?[\._\-]').firstMatch(trimmed);
    if (numMatch != null) {
      final num = int.tryParse(numMatch.group(1)!);
      if (num != null) {
        if (num >= 2160) return '4K';
        if (num >= 1440) return '1440p';
        if (num >= 1080) return '1080p';
        if (num >= 720) return '720p';
        if (num >= 480) return '480p';
        if (num >= 360) return '360p';
        if (num >= 240) return '240p';
      }
    }

    if (trimmed.length <= 10 &&
        !trimmed.contains('/') &&
        !trimmed.contains('.') &&
        !trimmed.contains('[')) {
      return trimmed;
    }

    return 'Auto';
  }

  static String? _normalizeResolutionWord(String word) {
    final lower = word.toLowerCase().trim();
    if (lower.contains('4k') ||
        lower.contains('2160') ||
        lower.contains('uhd')) {
      return '4K';
    }
    if (lower.contains('2k') ||
        lower.contains('1440') ||
        lower.contains('qhd')) {
      return '1440p';
    }
    if (lower.contains('1080') || lower.contains('fhd')) return '1080p';
    if (lower.contains('720') || lower.contains('hd')) return '720p';
    if (lower.contains('480') || lower.contains('sd')) return '480p';
    if (lower.contains('360')) return '360p';
    if (lower.contains('240')) return '240p';
    return null;
  }

  /// Extracts file size if present in string (e.g. "13.13 GB" from "[13.13 GB]").
  static String? extractSize(String? raw) {
    if (raw == null) return null;
    final match = _sizeRegex.firstMatch(raw);
    return match?.group(1)?.trim();
  }

  /// Extracts server or host name (e.g. "FSL Server" from "V-Cloud[FSL Server]").
  static String? extractServer(String raw) {
    final trimmed = raw.trim();

    // Pattern: Provider[Server Name] e.g. V-Cloud[FSL Server] or [FSL Server 2]
    final bracketMatch = RegExp(
      r'^(?:[A-Za-z0-9_\-\s]+)?\[([^\]]+)\]',
    ).firstMatch(trimmed);
    if (bracketMatch != null) {
      final inside = bracketMatch.group(1)!.trim();
      // Make sure it's not a file size or resolution
      if (!_sizeRegex.hasMatch(inside) &&
          _normalizeResolutionWord(inside) == null) {
        return inside;
      }
    }

    // Pattern: Server Name - ... or Server Name: ...
    final prefixMatch = RegExp(
      r'^([A-Za-z0-9\s]+(?:Server|Mirror|Cloud|Wish|Fast|Stream|Hub)[A-Za-z0-9\s]*?)[\s\-:]',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (prefixMatch != null) {
      return prefixMatch.group(1)!.trim();
    }

    // Pattern: Simple server name like "Server 1" or "FSL 2"
    final simpleMatch = RegExp(
      r'\b(Server\s*\d+|Mirror\s*\d+|Host\s*\d+)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (simpleMatch != null) {
      return simpleMatch.group(1)!.trim();
    }

    return null;
  }

  /// Extracts audio and codec highlights (e.g. "Atmos", "Dual Audio", "H.265").
  static String? extractAudioCodec(String raw) {
    final parts = <String>{};

    final audioMatch = _audioRegex.firstMatch(raw);
    if (audioMatch != null) {
      final a = audioMatch.group(0)!.trim();
      parts.add(a.replaceAll('-', ' '));
    }

    final codecMatch = _codecRegex.firstMatch(raw);
    if (codecMatch != null) {
      final c = codecMatch.group(0)!.trim();
      parts.add(c);
    }

    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  /// Cleans and formats a stream title for stream/server selection.
  /// E.g. "V-Cloud[FSL Server] Spider-Man...[13.13 GB] (4K)" -> "FSL Server • 4K (13.13 GB)"
  static String cleanStreamTitle(String? raw, {String? explicitSize}) {
    if (raw == null || raw.trim().isEmpty) return 'Auto';
    final trimmed = raw.trim();
    if (trimmed.toLowerCase() == 'auto') return 'Auto';

    // If it's already a clean simple quality like "1080p", "720p", "4K"
    if (_isCleanShortQuality(trimmed)) {
      if (explicitSize != null && explicitSize.isNotEmpty) {
        return '$trimmed ($explicitSize)';
      }
      return trimmed;
    }

    final server = extractServer(trimmed);
    final resolution = extractResolution(trimmed);
    final size = explicitSize ?? extractSize(trimmed);
    final audioCodec = extractAudioCodec(trimmed);

    final parts = <String>[];

    if (server != null && server.isNotEmpty) {
      parts.add(server);
    }

    if (resolution != 'Auto') {
      if (size != null && size.isNotEmpty) {
        parts.add('$resolution ($size)');
      } else {
        parts.add(resolution);
      }
    } else if (size != null && size.isNotEmpty) {
      parts.add(size);
    }

    if (audioCodec != null && audioCodec.isNotEmpty) {
      // Only append if title is short enough
      if (parts.length <= 2) {
        parts.add(audioCodec);
      }
    }

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    // Fallback: strip domains, file extensions, and repetitive dots
    return _stripNoiseFallback(trimmed);
  }

  /// Cleans and formats a quality label for the quality selector dropdown/sheet.
  /// E.g. "4K (13.13 GB) • FSL Server"
  static String cleanQualityLabel(String? raw, {String? explicitSize}) {
    if (raw == null || raw.trim().isEmpty) return 'Auto';
    final trimmed = raw.trim();
    if (trimmed.toLowerCase() == 'auto') return 'Auto';

    if (_isCleanShortQuality(trimmed)) {
      if (explicitSize != null && explicitSize.isNotEmpty) {
        return '$trimmed ($explicitSize)';
      }
      return trimmed;
    }

    final resolution = extractResolution(trimmed);
    final size = explicitSize ?? extractSize(trimmed);
    final server = extractServer(trimmed);
    final audioCodec = extractAudioCodec(trimmed);

    final parts = <String>[];

    final resLabel = StringBuffer();
    resLabel.write(resolution != 'Auto' ? resolution : 'Quality');
    if (size != null && size.isNotEmpty) {
      resLabel.write(' ($size)');
    }
    parts.add(resLabel.toString());

    if (server != null && server.isNotEmpty) {
      parts.add(server);
    } else if (audioCodec != null && audioCodec.isNotEmpty) {
      parts.add(audioCodec);
    }

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    return _stripNoiseFallback(trimmed);
  }

  /// Sanitizes any preference string to guarantee that long filenames or urls
  /// are never stored into the user's default quality setting.
  static String sanitizeDefaultQuality(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Auto';
    final trimmed = raw.trim();
    if (trimmed.toLowerCase() == 'auto') return 'Auto';

    const knownQualities = {
      'Auto',
      '4K',
      '1440p',
      '1080p',
      '720p',
      '480p',
      '360p',
      '240p',
    };
    if (knownQualities.contains(trimmed)) return trimmed;

    final extracted = extractResolution(trimmed);
    if (extracted != 'Auto') return extracted;

    // Allow clean short custom resolutions like "540p", "8K"
    if (trimmed.length <= 8 &&
        !trimmed.contains(' ') &&
        !trimmed.contains('/') &&
        !trimmed.contains('[') &&
        !trimmed.contains('.')) {
      return trimmed;
    }

    return 'Auto';
  }

  static bool _isCleanShortQuality(String str) {
    final lower = str.toLowerCase();
    const cleanList = [
      'auto',
      '4k',
      '1440p',
      '1080p',
      '720p',
      '480p',
      '360p',
      '240p',
      'fhd',
      'hd',
      'sd',
    ];
    return cleanList.contains(lower);
  }

  static String _stripNoiseFallback(String raw) {
    var cleaned = raw
        .replaceAll(_extRegex, '')
        .replaceAll(_domainRegex, '')
        .replaceAll(_releaseTagsRegex, '');

    // Replace dots and underscores with spaces
    cleaned = cleaned.replaceAll(RegExp(r'[\._]'), ' ');

    // Normalize multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.length > 40) {
      return '${cleaned.substring(0, 37).trim()}...';
    }
    return cleaned.isEmpty ? 'Stream' : cleaned;
  }
}
