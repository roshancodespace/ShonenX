import 'dart:convert';

import 'package:fjs/fjs.dart';
import 'package:http/http.dart' as http;

import '../Mangayomi/http/m_client.dart';

class FetchV2 {
  final JsEngine engine;
  FetchV2(this.engine);

  final _client = MClient.init();

  Future<void> inject() async {
    await engine.eval(
      source: const JsCode.code(r'''
      async function fetchv2(url, headers, method, body) {
        const res = await fjs.bridge_call({
          type: 'fetchv2',
          url,
          headers,
          method,
          body
        });

        return {
          status: res.status,
          headers: res.headers,
          ok: res.status >= 200 && res.status < 300,
          json() {
            return Promise.resolve(JSON.parse(res.body));
          },
          text() {
            return Promise.resolve(res.body);
          }
        };
      }
    '''),
    );
  }

  Future<JsResult> handle(Map data) async {
    final String url = data['url'];
    final String method = (data['method'] as String? ?? 'GET').toUpperCase();
    final dynamic body = data['body'];

    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
    };

    final Map? extHeaders = data['headers'];
    if (extHeaders != null) {
      for (final e in extHeaders.entries) {
        headers[e.key.toString()] = e.value.toString();
      }
    }

    try {
      http.Response response;

      switch (method) {
        case 'GET':
          response = await _client.get(Uri.parse(url), headers: headers);
          break;

        case 'HEAD':
          response = await _client.head(Uri.parse(url), headers: headers);
          break;

        case 'POST':
        case 'PUT':
        case 'PATCH':
        case 'DELETE':
          final request = http.Request(method, Uri.parse(url))
            ..headers.addAll(headers);

          if (body != null) {
            request.body = body is String ? body : jsonEncode(body);
          }

          final streamed = await _client.send(request);
          response = await http.Response.fromStream(streamed);
          break;

        default:
          return JsResult.err(
            JsError.cancelled('Unsupported HTTP method: $method'),
          );
      }

      return JsResult.ok(
        JsValue.object({
          'status': JsValue.integer(response.statusCode),
          'headers': JsValue.object(
            response.headers.map((k, v) => MapEntry(k, JsValue.string(v))),
          ),
          'body': JsValue.string(response.body),
        }),
      );
    } catch (e) {
      return JsResult.err(JsError.cancelled('fetchv2 failed: $e'));
    }
  }
}
