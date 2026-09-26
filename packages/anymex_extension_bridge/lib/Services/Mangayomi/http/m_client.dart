import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:collection/collection.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    as flutter_inappwebview;
import 'package:http/io_client.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../../../ExtensionBridge.dart';
import '../../../AnymeXBridge.dart';
import '../Eval/dart/model/m_source.dart';

class MClient {
  MClient();

  static InterceptedClient init({
    MSource? source,
    Map<String, dynamic>? reqcopyWith,
  }) {
    final client = AnymeXExtensionBridge.context.http ?? IOClient(HttpClient());
    return InterceptedClient.build(
      client: client,
      interceptors: [
        MCookieManager(reqcopyWith),
        LoggerInterceptor(),
      ],
    );
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
      cookies = cookie
              ?.split(RegExp('(?<=)(,)(?=[^;]+?=)'))
              .where((cookie) => cookie.isNotEmpty)
              .toList() ??
          [];
    } else {
      cookies = (await flutter_inappwebview.CookieManager.instance(
        webViewEnvironment: AnymeXExtensionBridge.context.webViewEnvironment,
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
      // saveData(PrefName.cookies, cookiesMap);
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

class MCookieManager extends InterceptorContract {
  MCookieManager(this.reqcopyWith);

  Map<String, dynamic>? reqcopyWith;

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final host = request.url.host;

    var cookieStr = AnymeXRuntimeBridge.cookiesMap[host];
    if (cookieStr == null) {
      final parts = host.split('.');
      if (parts.length >= 2) {
        final parentDomain = parts.sublist(parts.length - 2).join('.');
        cookieStr = AnymeXRuntimeBridge.cookiesMap[parentDomain];
      }
    }

    final existingCookie = request.headers.entries
        .firstWhereOrNull((e) => e.key.toLowerCase() == 'cookie')
        ?.value;
    String? finalCookie;
    if (existingCookie != null && existingCookie.isNotEmpty) {
      if (cookieStr != null && cookieStr.isNotEmpty) {
        finalCookie = _mergeCookies(cookieStr, existingCookie);
      } else {
        finalCookie = existingCookie;
      }
    } else {
      finalCookie = cookieStr;
    }
    if (finalCookie != null && finalCookie.isNotEmpty) {
      request.headers.removeWhere((k, v) => k.toLowerCase() == 'cookie');
      request.headers['Cookie'] = finalCookie;
    }

    var userAgent = AnymeXRuntimeBridge.userAgentMap[host];
    if (userAgent == null) {
      final parts = host.split('.');
      if (parts.length >= 2) {
        final parentDomain = parts.sublist(parts.length - 2).join('.');
        userAgent = AnymeXRuntimeBridge.userAgentMap[parentDomain];
      }
    }

    final existingUA = request.headers.entries
        .firstWhereOrNull((e) => e.key.toLowerCase() == 'user-agent')
        ?.value;
    String? finalUA;
    if (userAgent != null && userAgent.isNotEmpty) {
      // Prioritize the User-Agent that passed Cloudflare verification
      finalUA = userAgent;
    } else if (existingUA != null &&
        existingUA.isNotEmpty &&
        !existingUA.startsWith('Dart/')) {
      finalUA = existingUA;
      AnymeXRuntimeBridge.userAgentMap[host] = existingUA;
      final parts = host.split('.');
      if (parts.length >= 2) {
        final parentDomain = parts.sublist(parts.length - 2).join('.');
        AnymeXRuntimeBridge.userAgentMap[parentDomain] = existingUA;
      }
    } else {
      finalUA = userAgent;
    }
    if (finalUA != null && finalUA.isNotEmpty) {
      request.headers.removeWhere((k, v) => k.toLowerCase() == 'user-agent');
      request.headers['User-Agent'] = finalUA;
    }
    final existingContentType = request.headers.entries
        .firstWhereOrNull((e) => e.key.toLowerCase() == 'content-type')
        ?.value;
    if (existingContentType != null && existingContentType.isNotEmpty) {
      request.headers.removeWhere((k, v) => k.toLowerCase() == 'content-type');
      request.headers['Content-Type'] = existingContentType;
    }
    try {
      if (reqcopyWith != null) {
        if (reqcopyWith!["followRedirects"] != null) {
          request.followRedirects = reqcopyWith!["followRedirects"];
        }
        if (reqcopyWith!["maxRedirects"] != null) {
          request.maxRedirects = reqcopyWith!["maxRedirects"];
        }
        if (reqcopyWith!["contentLength"] != null) {
          request.contentLength = reqcopyWith!["contentLength"];
        }
        if (reqcopyWith!["persistentConnection"] != null) {
          request.persistentConnection = reqcopyWith!["persistentConnection"];
        }
      }
    } catch (_) {}
    return request;
  }

  String _mergeCookies(String bridgeCookie, String requestCookie) {
    final map = <String, String>{};
    void parse(String str) {
      for (final part in str.split(';')) {
        final index = part.indexOf('=');
        if (index != -1) {
          final key = part.substring(0, index).trim();
          final val = part.substring(index + 1).trim();
          if (key.isNotEmpty) {
            map[key] = val;
          }
        }
      }
    }
    parse(bridgeCookie);
    parse(requestCookie);
    return map.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return response;
  }
}

class LoggerInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    debugPrint(
      '----- Request -----\n${request.toString()}\nheader: ${request.headers.toString()}',
    );
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final server = response.headers["server"]?.toLowerCase() ?? "";
    final cloudflare = [403, 503].contains(response.statusCode) &&
        (server.contains("cloudflare") ||
            response.headers.containsKey("cf-ray") ||
            response.headers.containsKey("cf-cache-status"));
    debugPrint(
      "----- Response -----\n${response.request?.method}: ${response.request?.url}, statusCode: ${response.statusCode} ${cloudflare ? "Failed to bypass Cloudflare" : ""}",
    );
    if (cloudflare) {
      debugPrint("⚠️ [Cloudflare Block] ${response.statusCode} Failed to bypass Cloudflare for ${response.request?.url}");
    }
    return response;
  }
}
