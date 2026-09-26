import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'Logger.dart';
import 'Settings/KvStore.dart';
import 'Runtime/RuntimeDownloader.dart';
import 'Runtime/RuntimeController.dart';
import 'Runtime/RuntimePaths.dart';
import 'Runtime/Bridge/BridgeDispatcher.dart';
import 'dart:async';

class AnymeXRuntimeBridge {
  static const _channel = MethodChannel('anymeXBridge');

  static final Map<String, String> cookiesMap = {};
  static final Map<String, String> userAgentMap = {};

  static bool get isSupportedPlatform => !Platform.isIOS;

  static String? _cachedBridgePath;
  static String? _cachedToolsDirPath;
  static String? _cachedJreDirPath;
  static String _cachedVersion = '';
  static String _cachedReleaseTitle = '';
  static bool _hasLoadedMetadata = false;

  static Future<void> _initPathsAndLoadMetadata() async {
    if (_cachedBridgePath != null) return;
    try {
      final paths = RuntimePaths();
      _cachedBridgePath = await paths.bridgePath;
      _cachedToolsDirPath = (await paths.toolsDir).path;
      _cachedJreDirPath = (await paths.jreDir).path;

      await loadMetadata();
    } catch (e) {
      Logger.log("Error initializing paths: $e");
    }
  }

  static Future<void> loadMetadata() async {
    if (_cachedToolsDirPath == null) return;
    try {
      final metadataFile = File(p.join(_cachedToolsDirPath!, 'metadata.json'));
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final data = jsonDecode(content);
        _cachedVersion = data['version'] ?? '';
        _cachedReleaseTitle = data['title'] ?? '';
      } else {
        _cachedVersion = getVal<String>('runtime_host_installed_version',
                defaultValue: '') ??
            '';
        _cachedReleaseTitle = getVal<String>(
                'runtime_host_installed_release_title',
                defaultValue: '') ??
            '';

        if (_cachedVersion.isNotEmpty) {
          await metadataFile.writeAsString(jsonEncode({
            'version': _cachedVersion,
            'title': _cachedReleaseTitle,
          }));
        }
      }
    } catch (e) {
      Logger.log("Error loading metadata: $e");
    }
    _hasLoadedMetadata = true;
  }

  /// Setup the AnymeX Runtime Bridge (Android APK or Desktop JRE/JAR).
  /// This handles downloading, tracking progress, and initialization.
  /// Set [force] to true to re-download the Bridge JAR/APK (useful for updates).
  /// Note: The JRE is only downloaded if missing, regardless of [force].
  static Future<void> setupRuntime(
      {String? customDownloadUrl,
      bool force = false,
      String? localApkPath}) async {
    if (!isSupportedPlatform) return;
    await _initPathsAndLoadMetadata();
    await RuntimeDownloader().setupRuntime(
        customUrl: customDownloadUrl, force: force, localApkPath: localApkPath);
  }

  /// Explicitly sets and loads a custom local APK.
  /// This path is persisted and will be used automatically on future app restarts.
  static Future<bool> useLocalApk(String path) async {
    if (!Platform.isAndroid) return false;
    final exists = await File(path).exists();
    if (!exists) {
      Logger.log("useLocalApk: File does not exist at $path");
      return false;
    }

    try {
      setVal('runtime_host_path', path);
    } catch (e) {
      Logger.log('Failed to save runtime host APK path to KvStore: $e');
    }

    return await loadAnymeXRuntimeHost(path);
  }

  /// Checks if the runtime files already exist and initializes the bridge if they do.
  /// Call this on app startup to auto-load the bridge.
  static Future<void> checkAndInitialize() async {
    if (!isSupportedPlatform) return;
    await _initPathsAndLoadMetadata();

    final paths = RuntimePaths();

    String? savedPath;
    try {
      savedPath = getVal<String>('runtime_host_path');
    } catch (_) {}

    final bridgePath = (savedPath != null && await File(savedPath).exists())
        ? savedPath
        : await paths.bridgePath;

    final bridgeFile = File(bridgePath);
    bool exists = await bridgeFile.exists();

    if (!Platform.isAndroid) {
      final jreDir = await paths.jreDir;
      exists = exists && await jreDir.exists();
    }

    if (exists) {
      if (Platform.isAndroid) {
        final success = await loadAnymeXRuntimeHost(bridgePath);
        if (success) {
          controller.setReady(true);
        }
      } else {
        controller.setReady(true);
      }
      Logger.log(
          "AnymeX Bridge auto-detected and initialized from: $bridgePath");
    }
  }

  static RuntimeController get controller => RuntimeController.it;

  static Completer<bool>? _loadCompleter;

  /// Standard MethodChannel call for Android only
  static Future<bool> loadAnymeXRuntimeHost(String apkPath,
      {Map<String, dynamic>? settings}) async {
    if (!Platform.isAndroid) return false;

    if (_loadCompleter != null) {
      Logger.log("AnymeX Bridge is already loading, waiting for completion...");
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<bool>();

    final finalSettings = settings ?? {};

    try {
      final result =
          await _channel.invokeMethod<bool>('loadAnymeXRuntimeHost', {
        'path': apkPath,
        'settings': finalSettings,
      });
      final bool isLoaded = result ?? false;

      if (isLoaded) {
        try {
          setVal('runtime_host_path', apkPath);
        } catch (e) {
          Logger.log('Failed to save runtime host APK path to KvStore: $e');
        }
        controller.setReady(true);
      }

      _loadCompleter!.complete(isLoaded);
      return isLoaded;
    } catch (e) {
      print('Failed to load Runtime Host APK from $apkPath: $e');
      _loadCompleter?.complete(false);
      return false;
    } finally {
      _loadCompleter = null;
    }
  }

  /// Checks if the AnymeXBridgeHost is already loaded into memory.
  static Future<bool> isLoaded() async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('isLoaded');
        final loaded = result ?? false;
        if (loaded && !controller.isReady.value) {
          controller.setReady(true);
        }
        return loaded;
      } catch (e) {
        return false;
      }
    }
    return controller.isReady.value;
  }

  /// Cancels an active request in the Runtime Host using its [token].
  static Future<bool> cancelRequest(String token) async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('cancelRequest', {
          'token': token,
        });
        return result ?? false;
      } catch (e) {
        print('Failed to cancel request for token $token: $e');
        return false;
      }
    } else {
      return await BridgeDispatcher().cancelRequest(token);
    }
  }

  /// Pushes a set of cookies for the given [url] into the native OkHttp
  /// CookieJar used by all extensions (Aniyomi, CloudStream, Kotatsu).
  /// [url]          – origin URL the cookies belong to.
  /// [cookieString] – the raw `Set-Cookie` / `Cookie` header string,
  static Future<void> setCookies(String url, String cookieString) async {
    final effective = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    try {
      final host = Uri.parse(effective).host;
      if (host.isNotEmpty) {
        cookiesMap[host] = cookieString;
        final parts = host.split('.');
        if (parts.length > 2) {
          final parentDomain = parts.sublist(parts.length - 2).join('.');
          cookiesMap[parentDomain] = cookieString;
        }
      }
    } catch (_) {}
    if (!isSupportedPlatform) return;
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('setCookies', {
          'url': effective,
          'cookieString': cookieString,
        });
      } catch (e) {
        Logger.log('setCookies failed: $e');
      }
    } else {
      try {
        await BridgeDispatcher().invokeMethod('setCookies', {
          'url': effective,
          'cookieString': cookieString,
        });
      } catch (e) {
        Logger.log('setCookies (desktop) failed: $e');
      }
    }
  }

  /// Updates the User-Agent that all extensions will use when making requests
  /// to the given [url]'s domain.
  /// [url]       – origin URL whose domain this UA should apply to.
  /// [userAgent] – the User-Agent string captured from the WebView solve.
  static Future<void> setUserAgent(String url, String userAgent) async {
    final effective = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    try {
      final host = Uri.parse(effective).host;
      if (host.isNotEmpty) {
        userAgentMap[host] = userAgent;
        final parts = host.split('.');
        if (parts.length > 2) {
          final parentDomain = parts.sublist(parts.length - 2).join('.');
          userAgentMap[parentDomain] = userAgent;
        }
      }
    } catch (_) {}
    if (!isSupportedPlatform) return;
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('setUserAgent', {
          'url': effective,
          'userAgent': userAgent,
        });
      } catch (e) {
        Logger.log('setUserAgent failed: $e');
      }
    } else {
      try {
        await BridgeDispatcher().invokeMethod('setUserAgent', {
          'url': effective,
          'userAgent': userAgent,
        });
      } catch (e) {
        Logger.log('setUserAgent (desktop) failed: $e');
      }
    }
  }

  static const _aniyomiChannel = MethodChannel('aniyomiExtensionBridge');

  static final Map<String, Uint8List> _imageBytesCache = {};
  static final _imageSemaphore = _SimpleSemaphore(3);

  static Future<Uint8List?> getImageBytes(
      String sourceId, bool isAnime, String url) async {
    if (sourceId.isEmpty || sourceId == 'N/A' || url.isEmpty) return null;
    if (_imageBytesCache.containsKey(url)) {
      return _imageBytesCache[url]!;
    }
    if (!isSupportedPlatform) return null;
    await _imageSemaphore.acquire();
    try {
      Uint8List? bytes;
      if (Platform.isAndroid) {
        try {
          final result = await _aniyomiChannel.invokeMethod<Uint8List>('getImageBytes', {
            'sourceId': sourceId,
            'isAnime': isAnime,
            'url': url,
          });
          bytes = result;
        } catch (e) {
          Logger.log('getImageBytes failed: $e');
        }
      } else {
        try {
          final result = await BridgeDispatcher().invokeMethod('getImageBytes', {
            'sourceId': sourceId,
            'isAnime': isAnime,
            'url': url,
          });
          if (result != null) {
            bytes = Uint8List.fromList(List<int>.from(result));
          }
        } catch (e) {
          Logger.log('getImageBytes (desktop) failed: $e');
        }
      }
      if (bytes != null) {
        if (_imageBytesCache.length >= 150) {
          _imageBytesCache.remove(_imageBytesCache.keys.first);
        }
        _imageBytesCache[url] = bytes;
      }
      return bytes;
    } finally {
      _imageSemaphore.release();
    }
  }



  static String get installedVersion {
    if (!isPluginInstalled) return '';
    return _cachedVersion;
  }

  static String get installedReleaseTitle {
    if (!isPluginInstalled) return '';
    return _cachedReleaseTitle;
  }

  static bool get isPluginInstalled {
    if (_cachedBridgePath == null) return false;
    final bridgeFile = File(_cachedBridgePath!);
    if (!bridgeFile.existsSync()) return false;

    if (!Platform.isAndroid && _cachedJreDirPath != null) {
      final jreDir = Directory(_cachedJreDirPath!);
      if (!jreDir.existsSync()) return false;
    }

    if (_cachedToolsDirPath != null) {
      final metadataFile = File(p.join(_cachedToolsDirPath!, 'metadata.json'));
      if (!metadataFile.existsSync()) return false;
    }

    return _cachedVersion.isNotEmpty;
  }

  static void setInstalledRelease(String version, String title) {
    _cachedVersion = version;
    _cachedReleaseTitle = title;

    setVal('runtime_host_installed_version', version);
    setVal('runtime_host_installed_release_title', title);

    if (_cachedToolsDirPath != null) {
      try {
        final metadataFile =
            File(p.join(_cachedToolsDirPath!, 'metadata.json'));
        metadataFile.writeAsStringSync(jsonEncode({
          'version': version,
          'title': title,
        }));
      } catch (e) {
        Logger.log("Failed to write metadata.json: $e");
      }
    }
  }

  static Future<bool> isLoadedFromStorage() async {
    if (!Platform.isAndroid) return false;
    final savedPath = getVal<String>('runtime_host_path');
    if (savedPath == null || savedPath.isEmpty) return false;
    final defaultPath = await RuntimePaths().bridgePath;
    return savedPath != defaultPath;
  }
}

class _SimpleSemaphore {
  final int maxConcurrent;
  int _current = 0;
  final List<Completer<void>> _queue = [];

  _SimpleSemaphore(this.maxConcurrent);

  Future<void> acquire() async {
    if (_current < maxConcurrent) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.complete();
    } else {
      _current--;
    }
  }
}
