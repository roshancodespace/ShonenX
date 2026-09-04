import 'dart:async';

import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/episode_metadata/domain/models/episode_metadata.dart';
import 'package:shonenx/features/episode_metadata/services/anizip_metadata_provider.dart';
import 'package:shonenx/features/episode_metadata/services/jikan_metadata_provider.dart';
import 'package:shonenx/features/episode_metadata/services/kitsu_metadata_provider.dart';
import 'package:shonenx/features/episode_metadata/services/tenrai_metadata_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';

class EpisodeMetadataService {
  final AniZipEpisodeMetadataProvider _anizip;
  final TenraiEpisodeMetadataProvider _tenrai;
  final KitsuEpisodeMetadataProvider _kitsu;
  final JikanEpisodeMetadataProvider _jikan;
  final _log = AppLogger.scope('EpisodeMetadata');
  final _progressController = StreamController<String>.broadcast();

  Stream<String> get progressStream => _progressController.stream;

  EpisodeMetadataService({
    AniZipEpisodeMetadataProvider? anizip,
    TenraiEpisodeMetadataProvider? tenrai,
    KitsuEpisodeMetadataProvider? kitsu,
    JikanEpisodeMetadataProvider? jikan,
  }) : _anizip = anizip ?? AniZipEpisodeMetadataProvider(),
       _tenrai = tenrai ?? TenraiEpisodeMetadataProvider(),
       _kitsu = kitsu ?? KitsuEpisodeMetadataProvider(),
       _jikan = jikan ?? JikanEpisodeMetadataProvider();

  void _notify(String msg) {
    if (!_progressController.isClosed) {
      _progressController.add(msg);
    }
  }

  Future<List<UnifiedEpisode>> enrichEpisodes({
    required UnifiedMedia media,
    required List<UnifiedEpisode> sourceEpisodes,
    EpisodeMetadataProviderType mode = EpisodeMetadataProviderType.auto,
    TitlePreference? titlePreference,
  }) async {
    if (sourceEpisodes.isEmpty ||
        mode == EpisodeMetadataProviderType.disabled ||
        media.type == MediaType.MANGA ||
        media.type == MediaType.NOVEL) {
      return sourceEpisodes;
    }

    try {
      _notify('Resolving episode metadata...');
      List<EpisodeMetadata> metadata = [];

      if (mode == EpisodeMetadataProviderType.auto) {
        // Auto fallback chain: Tenrai -> Kitsu -> AniZip
        metadata = await _tenrai.fetchEpisodes(
          media: media,
          onProgress: _notify,
        );

        if (metadata.isEmpty) {
          _log.i('Tenrai returned no data, falling back to Kitsu');
          _notify('Tenrai unavailable, switching to Kitsu...');
          metadata = await _kitsu.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }

        if (metadata.isEmpty) {
          _log.i('Kitsu returned no data, falling back to AniZip');
          _notify('Kitsu unavailable, switching to AniZip...');
          metadata = await _anizip.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }
      } else if (mode == EpisodeMetadataProviderType.tenrai) {
        metadata = await _tenrai.fetchEpisodes(
          media: media,
          onProgress: _notify,
        );

        if (metadata.isEmpty) {
          _log.i('Tenrai returned no data, falling back to Kitsu');
          _notify('Tenrai unavailable, switching to Kitsu...');
          metadata = await _kitsu.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }

        if (metadata.isEmpty) {
          _log.i('Kitsu returned no data, falling back to AniZip');
          _notify('Kitsu unavailable, switching to AniZip...');
          metadata = await _anizip.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }
      } else if (mode == EpisodeMetadataProviderType.kitsu) {
        metadata = await _kitsu.fetchEpisodes(
          media: media,
          onProgress: _notify,
        );

        if (metadata.isEmpty) {
          _log.i('Kitsu returned no data, falling back to Tenrai');
          _notify('Kitsu unavailable, switching to Tenrai...');
          metadata = await _tenrai.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }

        if (metadata.isEmpty) {
          _log.i('Tenrai returned no data, falling back to AniZip');
          _notify('Tenrai unavailable, switching to AniZip...');
          metadata = await _anizip.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }
      } else if (mode == EpisodeMetadataProviderType.anizip) {
        metadata = await _anizip.fetchEpisodes(
          media: media,
          onProgress: _notify,
        );

        if (metadata.isEmpty) {
          _log.i('AniZip returned no data, falling back to Tenrai');
          _notify('AniZip unavailable, switching to Tenrai...');
          metadata = await _tenrai.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }

        if (metadata.isEmpty) {
          _log.i('Tenrai returned no data, falling back to Kitsu');
          _notify('Tenrai unavailable, switching to Kitsu...');
          metadata = await _kitsu.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }
      } else if (mode == EpisodeMetadataProviderType.jikan) {
        metadata = await _jikan.fetchEpisodes(
          media: media,
          onProgress: _notify,
        );

        if (metadata.isEmpty) {
          metadata = await _tenrai.fetchEpisodes(
            media: media,
            onProgress: _notify,
          );
        }
      }

      if (metadata.isEmpty) {
        _notify('');
        return sourceEpisodes;
      }

      _notify('Applying metadata to ${sourceEpisodes.length} episodes...');

      final metaMap = {for (final m in metadata) m.number: m};

      final result = sourceEpisodes.map((ep) {
        final meta =
            metaMap[ep.number] ??
            metaMap.entries
                .where((e) => (e.key - ep.number).abs() < 0.01)
                .firstOrNull
                ?.value;

        if (meta == null) return ep;

        final rawTitle = ep.title?.trim() ?? '';
        final isGeneric =
            rawTitle.isEmpty ||
            RegExp(
              r'^(Episode|Ep|Chapter|Ch\.?|\d+)\s*\d*$',
              caseSensitive: false,
            ).hasMatch(rawTitle) ||
            rawTitle == ep.number.toString() ||
            rawTitle == ep.number.toInt().toString();

        final preferredTitle = _resolvePreferredTitle(meta, titlePreference);

        final title = (isGeneric && preferredTitle?.isNotEmpty == true)
            ? preferredTitle
            : (rawTitle.isNotEmpty ? rawTitle : preferredTitle);

        final thumb = ep.thumbnailUrl?.isNotEmpty == true
            ? ep.thumbnailUrl
            : meta.thumbnailUrl;

        final airDate = ep.airDate?.isNotEmpty == true
            ? ep.airDate
            : meta.airDate;

        final desc = ep.description?.isNotEmpty == true
            ? ep.description
            : meta.description;

        final filler = meta.isFiller ?? ep.isFiller;

        return ep.copyWith(
          title: title,
          description: desc,
          thumbnailUrl: thumb,
          airDate: airDate,
          isFiller: filler,
        );
      }).toList();

      _notify('');
      return result;
    } catch (e, st) {
      _notify('');
      _log.e('Enrichment failed for "${media.title.availableTitle}"', [e, st]);
      return sourceEpisodes;
    }
  }

  String? _resolvePreferredTitle(
    EpisodeMetadata meta,
    TitlePreference? preference,
  ) {
    switch (preference) {
      case TitlePreference.romaji:
        if (meta.romanjiTitle?.isNotEmpty == true) return meta.romanjiTitle;
        if (meta.title?.isNotEmpty == true) return meta.title;
        return meta.japaneseTitle;
      case TitlePreference.native:
        if (meta.japaneseTitle?.isNotEmpty == true) return meta.japaneseTitle;
        if (meta.romanjiTitle?.isNotEmpty == true) return meta.romanjiTitle;
        return meta.title;
      case TitlePreference.english:
      case null:
        if (meta.title?.isNotEmpty == true) return meta.title;
        if (meta.romanjiTitle?.isNotEmpty == true) return meta.romanjiTitle;
        return meta.japaneseTitle;
    }
  }

  void dispose() {
    _progressController.close();
  }
}
