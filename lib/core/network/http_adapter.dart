import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/network/http_client.dart';

class HTTPAdapter extends http.BaseClient {
  final HTTP api;

  HTTPAdapter(this.api);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    HttpResponse response;

    switch (request.method.toUpperCase()) {
      case 'GET':
        response = await api.get(
          request.url.toString(),
          headers: request.headers,
        );
        break;

      case 'POST':
        final body = await request.finalize().bytesToString();

        response = await api.post(
          request.url.toString(),
          headers: request.headers,
          body: body,
        );
        break;

      default:
        throw UnsupportedError('Method ${request.method} not implemented');
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers ?? {},
    );
  }
}
