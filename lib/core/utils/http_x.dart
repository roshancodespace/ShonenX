import 'dart:convert';

import 'package:shonenx/core/network/http_client.dart';

extension HttpX on HTTP {
  Future<bool> isHLS(String url, {Map<String, String>? headers}) async {
    final cleanPath = url.split('?').first.split('#').first.toLowerCase();
    if (cleanPath.endsWith('.m3u8') || cleanPath.endsWith('.m3u')) {
      return true;
    }

    try {
      final response = await head(url, headers: headers);
      final contentType = response.headers?['content-type']?.toLowerCase();
      if (contentType != null && contentType.contains('mpegurl')) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<List<M3U8Quality>> splitM3U8(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (!await isHLS(url, headers: headers)) {
      return [];
    }

    try {
      final response = await get(url, headers: headers);
      if (response.statusCode != 200) {
        return [];
      }

      final body = response.body;
      final lines = LineSplitter.split(body).toList();
      if (!lines.any((l) => l.contains('#EXT-X-STREAM-INF'))) {
        return [];
      }

      final qualities = <M3U8Quality>[];
      final baseUri = Uri.parse(url);

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('#EXT-X-STREAM-INF') && i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          if (next.isNotEmpty && !next.startsWith('#')) {
            final resolvedUrl = _resolveUrl(baseUri, next);

            String? name = RegExp(
              r'NAME="([^"]+)"',
              caseSensitive: false,
            ).firstMatch(line)?.group(1);
            if (name == null || name.isEmpty) {
              final resolution = RegExp(
                r'RESOLUTION=(\d+x\d+)',
                caseSensitive: false,
              ).firstMatch(line)?.group(1);
              if (resolution != null) {
                name = '${resolution.split('x').last}p';
              }
            }
            final bandwidthStr = RegExp(
              r'BANDWIDTH=(\d+)',
              caseSensitive: false,
            ).firstMatch(line)?.group(1);

            String? estSize;
            if (bandwidthStr != null) {
              final bwVal = int.tryParse(bandwidthStr);
              if (bwVal != null && bwVal > 0) {
                // Estimate size for ~24 min episode (1440 sec)
                final bytes = (bwVal / 8) * 1440;
                estSize = '~${_formatM3u8Bytes(bytes.toInt())}';
              }
            }

            if (name == null || name.isEmpty && bandwidthStr != null) {
              final bwVal = int.tryParse(bandwidthStr!) ?? 0;
              name = '${(bwVal / 1000).round()} kbps';
            }
            if (name.isEmpty) {
              name = 'Quality ${qualities.length + 1}';
            }

            qualities.add(
              M3U8Quality(quality: name, url: resolvedUrl, size: estSize),
            );
          }
        }
      }
      return qualities;
    } catch (_) {
      return [];
    }
  }

  String _formatM3u8Bytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  String _resolveUrl(Uri baseUri, String url) {
    final parsed = Uri.parse(url);
    if (parsed.hasScheme) return url;

    final resolved = baseUri.resolve(url);
    if (baseUri.hasQuery && !parsed.hasQuery) {
      return resolved.replace(query: baseUri.query).toString();
    }
    return resolved.toString();
  }
}

class M3U8Quality {
  final String quality;
  final String url;
  final String? size;
  const M3U8Quality({required this.quality, required this.url, this.size});
}
