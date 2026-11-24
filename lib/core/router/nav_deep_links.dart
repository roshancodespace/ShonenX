import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/app_init.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/models/unified_media.dart';

mixin NavDeepLinkHandling<T extends StatefulWidget> on State<T> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void initNavDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      handleDeepLink(uri);
    });
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) handleDeepLink(uri);
    });

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      FlutterSingleInstance.onFocus = (metadata) {
        if (metadata.containsKey('args')) {
          final argsList = metadata['args'] as List<dynamic>?;
          if (argsList != null && argsList.isNotEmpty) {
            for (final arg in argsList) {
              final uri = Uri.tryParse(arg.toString());
              if (uri != null && uri.scheme.isNotEmpty) {
                handleDeepLink(uri);
                break;
              }
            }
          }
        }
      };
    }
  }

  @protected
  void handleDeepLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (host == 'anilist.co' ||
        host == 'myanimelist.net' ||
        host == 'kitsu.io' ||
        host == 'kitsu.app') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final mediaTypeStr = pathSegments[0].toLowerCase();
        final id = pathSegments[1];
        MediaType? mediaType;
        if (mediaTypeStr == 'anime') mediaType = MediaType.ANIME;
        if (mediaTypeStr == 'manga') mediaType = MediaType.MANGA;

        if (mediaType != null) {
          String providerId = 'anilist';
          if (host == 'myanimelist.net') providerId = 'myanimelist';
          if (host == 'kitsu.io' || host == 'kitsu.app') providerId = 'kitsu';

          final media = UnifiedMedia(
            id: id,
            title: MediaTitle(english: 'Loading...'),
            type: mediaType,
            providerId: providerId,
          );

          context.pushDetails(mediaType: mediaType, media: media);
          return;
        }
      }
    }

    if ((scheme == 'aniyomi' ||
            scheme == 'tachiyomi' ||
            scheme == 'mangayomi' ||
            scheme.contains('cloudstream') ||
            scheme == 'kotatsu' ||
            scheme == 'sora' ||
            scheme == 'shonenx') &&
        (host == 'add-repo' ||
            host == 'add-repository' ||
            scheme == 'cloudstreamrepo' ||
            uri.queryParameters.containsKey('url'))) {
      String? url = uri.queryParameters['url'];
      String? managerId;
      String? type;

      if (scheme == 'aniyomi') {
        managerId = 'aniyomi';
        type = 'anime';
      } else if (scheme == 'tachiyomi') {
        managerId = 'aniyomi';
        type = 'manga';
      } else if (scheme == 'mangayomi') {
        managerId = 'mangayomi';
      } else if (scheme.contains('cloudstream')) {
        managerId = 'cloudstream';
        if (url == null &&
            host.isNotEmpty &&
            host != 'add-repo' &&
            host != 'add-repository') {
          url = uri.toString().replaceFirst(
            RegExp(
              r'^cloudstreamrepo://|^cloudstream://',
              caseSensitive: false,
            ),
            '',
          );
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://$url';
          }
        }
      } else if (scheme == 'kotatsu') {
        managerId = 'kotatsu';
        type = 'manga';
      } else if (scheme == 'sora') {
        managerId = 'sora';
        type = 'novel';
      } else if (scheme == 'shonenx' && host == 'add-repo') {
        managerId = uri.queryParameters['manager'] ?? 'aniyomi';
        type = uri.queryParameters['type'];
      }

      final targetUri = Uri(
        path: '/settings/extensions',
        queryParameters: {
          if (url != null && url.isNotEmpty && url != '()') 'autoAddUrl': url,
          if (managerId != null) 'autoAddManager': managerId,
          if (type != null) 'autoAddType': type,
        },
      );
      final target = targetUri.toString();

      try {
        final currentUri = GoRouterState.of(context).uri;
        if (currentUri.path == '/settings/extensions' &&
            currentUri.queryParameters['autoAddUrl'] == url) {
          return;
        }
      } catch (_) {}

      context.pushSettings();
      context.pushPendingLink(target);
    }
  }

  void checkPendingDeepLink() {
    final pendingLink = AppInit.pendingDeepLink;
    if (pendingLink != null) {
      AppInit.pendingDeepLink = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushSettings();
          context.pushPendingLink(pendingLink);
        }
      });
    }
  }

  void disposeNavDeepLinks() {
    _linkSubscription?.cancel();
  }
}
