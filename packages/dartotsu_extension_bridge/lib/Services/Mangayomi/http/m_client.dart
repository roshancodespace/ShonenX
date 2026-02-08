import 'dart:async';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    as flutter_inappwebview;
import 'package:http/io_client.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../../../extension_bridge.dart';
import '../Eval/dart/model/m_source.dart';

class MClient {
  MClient();

  static InterceptedClient init({
    MSource? source,
    Map<String, dynamic>? reqcopyWith,
  }) {
    var client = reqcopyWith?["useDartHttpClient"] == true || httpClient == null
        ? IOClient(HttpClient())
        : httpClient;
    return InterceptedClient.build(client: client, interceptors: []);
  }

  static Map<String, String> getCookiesPref(String url) {
    final cookiesMap = {}; //loadData(PrefName.cookies);
    if (cookiesMap.isEmpty) return {};

    final urlHost = Uri.parse(url).host;

    final matchingEntry = cookiesMap.entries.firstWhere(
      (entry) => urlHost == entry.key || urlHost.contains(entry.key),
      orElse: () => const MapEntry('', ''),
    );

    final cookies = matchingEntry.value;
    if (cookies.isEmpty) return {};

    return {HttpHeaders.cookieHeader: cookies};
  }

  static Future<void> setCookie(
    String url,
    String ua,
    flutter_inappwebview.InAppWebViewController? webViewController, {
    String? cookie,
  }) async {
    List<String> cookies = [];
    if (Platform.isLinux) {
      cookies =
          cookie
              ?.split(RegExp('(?<=)(,)(?=[^;]+?=)'))
              .where((cookie) => cookie.isNotEmpty)
              .toList() ??
          [];
    } else {
      cookies =
          (await flutter_inappwebview.CookieManager.instance(
                webViewEnvironment: webViewEnvironment,
              ).getCookies(
                url: flutter_inappwebview.WebUri(url),
                webViewController: webViewController,
              ))
              .map((e) => "${e.name}=${e.value}")
              .toList();
    }
    if (cookies.isNotEmpty) {
      final host = Uri.parse(url).host;
      final newCookie = cookies.join("; ");
      final cookiesMap = {}; //loadData(PrefName.cookies);
      cookiesMap.removeWhere((key, value) => key == host || host.contains(key));
      cookiesMap[host] = newCookie;
      //saveData(PrefName.cookies, cookiesMap);
    }
    if (ua.isNotEmpty) {
      //saveData(PrefName.userAgent, ua);
    }
  }

  static void deleteAllCookies(String url) {
    final cookiesMap = {}; //loadData(PrefName.cookies);
    final urlHost = Uri.parse(url).host;
    cookiesMap.removeWhere(
      (host, cookie) => host == urlHost || urlHost.contains(host),
    );
    //saveData(PrefName.cookies, cookiesMap);
  }
}
