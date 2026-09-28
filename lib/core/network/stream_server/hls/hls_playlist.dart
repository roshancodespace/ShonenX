import 'dart:convert';
import 'dart:io';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';

import 'hls_stream.dart';

class HlsPlaylist {
  static final _log = AppLogger.scope(HlsPlaylist);

  static Future<void> processPlaylist(
    HttpRequest request,
    HlsStream stream,
    HTTP httpClient,
    int serverPort,
  ) async {
    final response = request.response;

    // Check if there is an explicit upstream URL (for nested playlists)
    final urlStr = request.uri.queryParameters['url'];
    final upstreamUrl = urlStr != null
        ? utf8.decode(base64Url.decode(urlStr))
        : stream.upstreamUrl;

    try {
      final res = await httpClient.get(
        upstreamUrl,
        headers: stream.headers,
        forceRefresh: true, // Always get a fresh playlist
        suppressLogs: true,
      );

      final body = res.body;
      final lines = LineSplitter.split(body).toList();
      final rewrittenLines = <String>[];

      final baseUri = Uri.parse(upstreamUrl);

      String? currentKeyUrl;
      String? currentIvStr;
      int mediaSequence = 0;

      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          rewrittenLines.add(line);
          continue;
        }

        if (trimmed.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
          rewrittenLines.add(line);
          final match = RegExp(
            r'#EXT-X-MEDIA-SEQUENCE:(\d+)',
          ).firstMatch(trimmed);
          if (match != null) {
            mediaSequence = int.parse(match.group(1)!);
          }
        } else if (trimmed.startsWith('#EXT-X-KEY:')) {
          final methodMatch = RegExp(r'METHOD=([^,]+)').firstMatch(trimmed);
          if (methodMatch != null) {
            final method = methodMatch.group(1);
            if (method == 'NONE') {
              currentKeyUrl = null;
              currentIvStr = null;
            } else if (method == 'AES-128') {
              final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(trimmed);
              if (uriMatch != null) {
                currentKeyUrl = _resolveUrl(baseUri, uriMatch.group(1)!);
              }
              final ivMatch = RegExp(r'IV=([^,]+)').firstMatch(trimmed);
              if (ivMatch != null) {
                currentIvStr = ivMatch.group(1);
              }
            }
          }
          // Do NOT add #EXT-X-KEY to the rewritten playlist
        } else if (trimmed.startsWith('#') &&
            !trimmed.startsWith('#EXT-X-STREAM-INF')) {
          rewrittenLines.add(line);
        } else if (trimmed.startsWith('#EXT-X-STREAM-INF')) {
          rewrittenLines.add(line);
        } else {
          // It's a URI
          final absoluteUrl = _resolveUrl(baseUri, trimmed);
          final encodedUrl = base64Url.encode(utf8.encode(absoluteUrl));

          if (absoluteUrl.toLowerCase().contains('.m3u8') ||
              absoluteUrl.toLowerCase().contains('.m3u')) {
            rewrittenLines.add(
              'http://127.0.0.1:$serverPort/stream/${stream.id}/playlist.m3u8?url=$encodedUrl',
            );
          } else {
            var localSegmentUrl =
                'http://127.0.0.1:$serverPort/stream/${stream.id}/segment?url=$encodedUrl';
            if (currentKeyUrl != null) {
              final encodedKeyUrl = base64Url.encode(
                utf8.encode(currentKeyUrl),
              );
              final ivToPass = currentIvStr ?? mediaSequence.toString();
              localSegmentUrl += '&key=$encodedKeyUrl&iv=$ivToPass';
            }
            rewrittenLines.add(localSegmentUrl);
            mediaSequence++;
          }
        }
      }

      final rewrittenBody = rewrittenLines.join('\n');
      response.headers.contentType = ContentType.parse(
        'application/vnd.apple.mpegurl',
      );
      response.statusCode = HttpStatus.ok;
      response.write(rewrittenBody);
      await response.close();
    } catch (e) {
      _log.e('Failed to process playlist', e);
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } catch (_) {}
    }
  }

  static String _resolveUrl(Uri baseUri, String url) {
    final parsed = Uri.parse(url);
    if (parsed.hasScheme) return url;

    final resolved = baseUri.resolve(url);
    if (baseUri.hasQuery && !parsed.hasQuery) {
      return resolved.replace(query: baseUri.query).toString();
    }
    return resolved.toString();
  }
}
