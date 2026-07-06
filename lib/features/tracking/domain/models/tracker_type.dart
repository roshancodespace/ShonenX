import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/engine/trackers/anilist/anilist_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/kitsu/kitsu_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/local/local_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/mal/mal_tracker.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/shared/providers/database_provider.dart';

enum TrackerType {
  anilist('AniList'),
  myanimelist('MyAnimeList'),
  kitsu('Kitsu'),
  local('Local');

  final String displayName;
  const TrackerType(this.displayName);

  String get id => name;

  factory TrackerType.fromId(String id) {
    return values.firstWhere((e) => e.id == id);
  }

  static TrackerType? tryFromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

extension TrackerTypeX on TrackerType {
  bool isAuthenticated(WidgetRef ref) =>
      this == TrackerType.local ||
      ref.watch(trackerProfileProvider)[this] != null;

  TrackerProfile? getProfile(WidgetRef ref) =>
      ref.watch(trackerProfileProvider)[this];

  TrackingService getTracker(Ref ref) {
    switch (this) {
      case TrackerType.anilist:
        return AnilistTracker(ref);
      case TrackerType.myanimelist:
        return MalTracker(ref);
      case TrackerType.kitsu:
        return KitsuTracker(ref);
      case TrackerType.local:
        return LocalTracker(ref.watch(databaseProvider));
    }
  }

  Widget getIconWidget({double size = 24, Color? color}) {
    if (this == TrackerType.local) {
      return Icon(Icons.folder_special_rounded, size: size, color: color);
    }
    final source = iconSvgString;
    if (source.trimLeft().startsWith('<')) {
      return SvgPicture.string(
        source,
        width: size,
        height: size,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      );
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: source,
        width: size,
        height: size,
        color: color,
        placeholder: (_, __) => SizedBox(width: size, height: size),
        errorWidget: (_, __, ___) =>
            Icon(Icons.error_outline, size: size, color: color),
      );
    } else if (source.startsWith('assets/')) {
      return Image.asset(source, width: size, height: size, color: color);
    } else {
      return Icon(Icons.extension_rounded, size: size, color: color);
    }
  }

  String get iconSvgString {
    switch (this) {
      case TrackerType.anilist:
        return '''
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path fill="currentColor" d="M24 17.53v2.421c0 .71-.391 1.101-1.1 1.101h-5l-.057-.165L11.84 3.736c.106-.502.46-.788 1.053-.788h2.422c.71 0 1.1.391 1.1 1.1v12.38H22.9c.71 0 1.1.392 1.1 1.101zM11.034 2.947l6.337 18.104h-4.918l-1.052-3.131H6.019l-1.077 3.131H0L6.361 2.948h4.673zm-.66 10.96l-1.69-5.014l-1.541 5.015h3.23z" />
        </svg>
        ''';
      case TrackerType.myanimelist:
        return '''
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
          <path fill="currentColor" d="M14.921 6.479c-.82 0-3.683 0-4.947 3.156c-.662 1.652-.986 4.812.876 7.886l1.934-1.41s-.767-1.095-1.083-3.191h2.897l.022 3.19h2.604V8.835h-2.581v2.043l-2.46-.023s.413-2.408 2.877-2.336h2.454l-.572-2.04ZM0 6.528v9.624h2.348v-5.84l2.031 2.664l2.047-2.652v5.828h2.336V6.528H6.437L4.368 9.474L2.31 6.528Zm18.447.022v9.583h5.022L24 14.09h-3.232V6.55Z" />
        </svg>
        ''';
      case TrackerType.kitsu:
        return '''
        <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
          <path d="M0 0h24v24H0z" fill="none" />
          <path fill="currentColor" d="M1.429 5.441a12.5 12.5 0 0 0 1.916 2.056c.011.011.022.011.022.022c.452.387 1.313.947 1.937 1.173c0 0 3.886 1.496 4.091 1.582a1.4 1.4 0 0 0 .237.075a.694.694 0 0 0 .808-.549c.011-.065.022-.172.022-.248V5.161c.011-.667-.205-1.679-.398-2.239c0-.011-.011-.022-.011-.032A12 12 0 0 0 8.824.36L8.781.285a.697.697 0 0 0-.958-.162c-.054.032-.086.075-.129.119L7.608.36a4.74 4.74 0 0 0-.786 3.412a8 8 0 0 0-.775.463c-.043.032-.42.291-.71.56A4.8 4.8 0 0 0 1.87 4.3c-.043.011-.097.021-.14.032c-.054.022-.107.043-.151.076a.7.7 0 0 0-.193.958zM8.222 1.07c.366.614.678 1.249.925 1.917q-.743.129-1.453.388a3.9 3.9 0 0 1 .528-2.305M4.658 5.463a7.5 7.5 0 0 0-.893 1.216a11.7 11.7 0 0 1-1.453-1.55a3.83 3.83 0 0 1 2.346.334m13.048-.302a7.7 7.7 0 0 0-2.347-.474a7.6 7.6 0 0 0-3.811.818l-.215.108v3.918c0 .054 0 .258-.032.431a1.54 1.54 0 0 1-.646.98a1.55 1.55 0 0 1-1.152.247a2.6 2.6 0 0 1-.409-.118a748 748 0 0 1-3.402-1.313a9 9 0 0 0-.323-.129a30.6 30.6 0 0 0-3.822 3.832l-.075.086a.698.698 0 0 0 .538 1.098a.68.68 0 0 0 .42-.118c.011-.011.022-.022.043-.032c1.313-.947 2.756-1.712 4.284-2.325a.7.7 0 0 1 .818.13a.704.704 0 0 1 .054.915l-.237.388a20.3 20.3 0 0 0-1.97 4.306l-.032.129a.65.65 0 0 0 .108.538a.71.71 0 0 0 .549.301a.66.66 0 0 0 .42-.118c.054-.043.108-.086.151-.14l.043-.065a19 19 0 0 1 1.765-2.153a20.16 20.16 0 0 1 10.797-6.018c.032-.011.065-.011.097-.011c.237.011.42.215.409.452a.424.424 0 0 1-.344.398c-3.908.829-10.948 5.469-8.483 12.208c.043.108.075.172.129.269a.71.71 0 0 0 .538.301a.74.74 0 0 0 .657-.398c.398-.754 1.152-1.593 3.326-2.497c6.061-2.508 7.062-6.093 7.17-8.364v-.129a7.72 7.72 0 0 0-5.016-7.451m-6.083 17.762c-.56-1.669-.506-3.283.151-4.823c1.26 2.035 3.456 2.207 3.456 2.207c-2.25.937-3.133 1.863-3.607 2.616" />
        </svg>
        ''';
      case TrackerType.local:
        return '';
      // ignore: unreachable_switch_default
      default:
        return '';
    }
  }
}
