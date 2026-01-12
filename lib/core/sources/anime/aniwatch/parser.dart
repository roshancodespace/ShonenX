import 'dart:convert';
import 'dart:developer';

import 'package:html/dom.dart' as dom;
// Will change depecrated models to new models
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';

SearchPage parseSearch(dom.Document document, String baseUrl,
    {required String keyword, required int page}) {
  return _parseSearchPage(document, baseUrl, page);
}

SearchPage parsePage(dom.Document document, String baseUrl,
    {required String route, required int page}) {
  return _parseSearchPage(document, baseUrl, page);
}

SearchPage _parseSearchPage(dom.Document document, String baseUrl, int page) {
  return SearchPage(
    totalPages: _extractTotalPages(document) ?? 1,
    currentPage: page,
    results: _extractAnimeResults(document, baseUrl),
  );
}

int? _extractTotalPages(dom.Document document) {
  final lastPageLink =
      document.querySelector('ul.pagination > li:last-child > a');
  return _parseNumber(lastPageLink?.attributes['href']?.split('=').last);
}

List<BaseAnimeModel> _extractAnimeResults(
    dom.Document document, String baseUrl) {
  return document
      .querySelectorAll('.flw-item')
      .map((anime) => _parseAnime(anime, baseUrl))
      .toList();
}

BaseAnimeModel _parseAnime(dom.Element element, String baseUrl) {
  final id = _extractAnimeId(element);
  final poster = element.querySelector('img')?.attributes['data-src'];
  final name = element.querySelector('.film-name > a')?.text;
  final jname = element.querySelector('.film-name a')?.attributes['data-jname'];
  final extra = element.querySelectorAll('.fd-infor .fdi-item');
  final type = extra.first.text;
  final duration = extra.last.text;

  return BaseAnimeModel(
    id: id,
    poster: poster,
    url: '$baseUrl${element.querySelector('a')?.attributes['href']}',
    name: name,
    jname: jname,
    type: type,
    duration: duration,
  );
}

String? _extractAnimeId(dom.Element element) {
  return element
      .querySelector('a')
      ?.attributes['href']
      ?.split('/')
      .last
      .split('?')
      .first;
}

List<BaseAnimeModel> parseTrending(dom.Document document, String baseUrl) {
  return document.querySelectorAll("#anime-trending div.item").map((anime) {
    return _parseTrendingAnime(anime, baseUrl);
  }).toList();
}

BaseAnimeModel _parseTrendingAnime(dom.Element anime, String baseUrl) {
  final url = anime.querySelector('a')?.attributes['href'] ?? '';
  final img = anime.querySelector('img')?.attributes['data-src'] ?? '';

  return BaseAnimeModel(
    url: '$baseUrl$url',
    poster: img,
    number: _parseNumber(anime.querySelector('.number > span')?.text),
    name: anime.querySelector('.film-title')?.text,
    jname: anime.querySelector('.film-title')?.attributes['data-jname'],
  );
}

List<BaseAnimeModel> parseSpotlight(dom.Document document, String baseUrl) {
  return document
      .querySelectorAll('.swiper-wrapper .deslide-item')
      .map((anime) {
    return _parseSpotlightAnime(anime, baseUrl);
  }).toList();
}

BaseAnimeModel _parseSpotlightAnime(dom.Element anime, String baseUrl) {
  return BaseAnimeModel(
    id: '${anime.querySelector('a')?.attributes['href']?.split('/').last}',
    url: '$baseUrl${anime.querySelector('a')?.attributes['href'] ?? ''}',
    banner:
        anime.querySelector('.film-poster-img')?.attributes['data-src'] ?? '',
    name: anime.querySelector('.desi-head-title')?.text,
    jname: anime.querySelector('.desi-head-title')?.attributes['data-jname'],
    description: anime.querySelector('.desi-description')?.text.trim(),
    rank: _parseNumber(
        anime.querySelector('.desi-sub-text')?.text.split(' ')[0].substring(1)),
    type: anime.querySelector('.sc-detail .scd-item:first-child')?.text.trim(),
    duration: anime.querySelectorAll('.sc-detail .scd-item')[1].text.trim(),
    releaseDate:
        anime.querySelector('.sc-detail .scd-item.m-hide')?.text.trim(),
    episodes: _extractEpisodes(anime),
  );
}

EpisodesModel _extractEpisodes(dom.Element anime) {
  return EpisodesModel(
    sub: _parseNumber(
        anime.querySelector('.sc-detail .tick-item tick-sub')?.text),
    dub: _parseNumber(
        anime.querySelector('.sc-detail .tick-item tick-dub')?.text),
    total: _parseNumber(
        anime.querySelector('.sc-detail .tick-item tick-eps')?.text),
  );
}

List<Featured> parseFeatured(dom.Document document, String baseUrl) {
  final List<Featured> sections = [];
  final sectionsFound = <String>[];

  document
      .querySelectorAll('#anime-featured div.anif-block')
      .forEach((section) {
    final sectionTitle = section.querySelector('.anif-block-header')?.text;
    final sectionInUrlPath =
        section.querySelector('.more a')?.attributes['href']?.split('/').last;

    final sectionAnimes = _extractFeaturedAnimes(section, baseUrl);
    sections.add(Featured(
      path: sectionInUrlPath,
      title: sectionTitle,
      animes: sectionAnimes,
    ));
    sectionsFound.add(sectionTitle ?? 'Untitled');
  });

  _logSectionsFound(sectionsFound);
  return sections;
}

List<BaseAnimeModel> _extractFeaturedAnimes(
    dom.Element section, String baseUrl) {
  return section.querySelectorAll('.anif-block-ul li').map((anime) {
    return _parseFeaturedAnime(anime, baseUrl);
  }).toList();
}

BaseAnimeModel _parseFeaturedAnime(dom.Element anime, String baseUrl) {
  final id = anime.querySelector('a')?.attributes['href']?.substring(1);
  final img = anime.querySelector('img')?.attributes['data-src'];
  final url = anime.querySelector('a')?.attributes['href'];
  final title = anime.querySelector('.film-name a');
  final extra = anime.querySelector('.fd-infor');

  return BaseAnimeModel(
    id: id,
    url: '$baseUrl$url',
    poster: img,
    name: title?.text,
    jname: title?.attributes['data-jname'],
    type: extra?.querySelector('.fdi-item')?.text,
    episodes: extra != null ? _extractEpisodes(extra) : null,
  );
}

void _logSectionsFound(List<String> sectionsFound) {
  if (sectionsFound.isEmpty) {}
}

DetailPage parseDetail(dom.Document document, String baseUrl,
    {required String animeId}) {
  final BaseAnimeModel anime = _extractDetailAnime(document, baseUrl, animeId);
  return DetailPage(anime: anime);
}

BaseAnimeModel _extractDetailAnime(
    dom.Document document, String baseUrl, String animeId) {
  return BaseAnimeModel(
    id: animeId,
    anilistId: _parseNumber(
        jsonDecode(document.querySelector('#syncData')!.text)['anilist_id']),
    url: '$baseUrl$animeId',
    name: document.querySelector('.anisc-detail .film-name')?.text,
    jname: document
        .querySelector('.anisc-detail .film-name')
        ?.attributes['data-jname'],
    poster: document
        .querySelector('.anisc-poster .film-poster-img')
        ?.attributes['src'],
    description: document
        .querySelector('.anisc-detail .film-description .text')
        ?.text
        .trim(),
    type: document.querySelectorAll('.film-stats .tick .item').first.text,
    duration: document.querySelectorAll('.film-stats .tick .item').last.text,
    genres: _extractGenres(document),
    episodes: _extractDetailEpisodes(document),
  );
}

List<String> _extractGenres(dom.Document document) {
  return document
      .querySelectorAll('.anisc-info-wrap .item-list a')
      .map((genre) => genre.attributes['title'] ?? genre.text.trim())
      .toList();
}

EpisodesModel _extractDetailEpisodes(dom.Document document) {
  return EpisodesModel(
    sub: _parseNumber(
        document.querySelector('.anisc-detail .film-stats .tick-sub')?.text),
    dub: _parseNumber(
        document.querySelector('.anisc-detail .film-stats .tick-dub')?.text),
    total: _parseNumber(
        document.querySelector('.anisc-detail .film-stats .tick-eps')?.text),
  );
}

WatchPage parseWatch(dom.Document document, String baseUrl,
    {required String animeId}) {
  return WatchPage(
    totalEpisodes: _extractTotalEpisodes(document),
    anime: _extractWatchAnime(document, baseUrl, animeId),
  );
}

int _extractTotalEpisodes(dom.Document document) {
  return _parseNumber(
        document
            .querySelector('.dropdown-menu a.dropdown-item-ep-page-item')
            ?.text
            .split('-')
            .last
            .trim(),
      ) ??
      0;
}

BaseAnimeModel _extractWatchAnime(
    dom.Document document, String baseUrl, String animeId) {
  return BaseAnimeModel(
    id: animeId,
    url: '$baseUrl/$animeId',
    name: document.querySelector('.anis-detail .film-name a')?.text,
    jname: document
        .querySelector('.anis-detail .film-name a')
        ?.attributes['data-jname'],
    poster: document.querySelector('.anis-poster img')?.attributes['data-src'],
    description:
        document.querySelector('.anis-detail .film-description .text')?.text,
    type: document
        .querySelector('.anisc-detail .film-stats .item:first-child')
        ?.text,
    duration: document
        .querySelector('.anisc-detail .film-stats .item:last-child')
        ?.text,
    episodes: _extractWatchEpisodes(document),
  );
}

EpisodesModel _extractWatchEpisodes(dom.Document document) {
  return EpisodesModel(
    sub: _parseNumber(
        document.querySelector('.anisc-detail .film-stats .tick-sub')?.text),
    dub: _parseNumber(
        document.querySelector('.anisc-detail .film-stats .tick-dub')?.text),
    total: _parseNumber(
        document.querySelector('.anisc-detail .film-stats .tick-eps')?.text),
  );
}

BaseEpisodeModel parseEpisodes(dom.Document document, String baseUrl,
    {required String animeId}) {
  final episodes = _extractEpisodesList(document, baseUrl);
  return BaseEpisodeModel(
    totalEpisodes: episodes.length,
    episodes: episodes,
  );
}

List<EpisodeDataModel> _extractEpisodesList(
    dom.Document document, String baseUrl) {
  return document
      .querySelectorAll('.ss-list > a.ssl-item.ep-item')
      .map((episode) {
    return _parseEpisode(episode, baseUrl);
  }).toList();
}

EpisodeDataModel _parseEpisode(dom.Element episode, String baseUrl) {
  final id = episode.attributes['data-id'];
  final number = _parseNumber(episode.attributes['data-number']);
  final title = episode.attributes['title'];
  final relativeUrl = episode.attributes['href'] ?? '';
  final episodeUrl = Uri.parse(baseUrl).resolve(relativeUrl).toString();
  final isFiller = episode.classes.contains('ssl-item-filler');

  return EpisodeDataModel(
    id: id,
    number: number ?? 0,
    title: title ?? 'Episode ${number ?? "N/A"}',
    url: episodeUrl,
    isFiller: isFiller,
  );
}

BaseServerModel parseServers(dom.Document document, String baseUrl) {
  final subServers = _extractServers(document, 'sub');
  final dubServers = _extractServers(document, 'dub');

  log("Sub servers: ${subServers.length}");
  log("Dub servers: ${dubServers.length}");

  return BaseServerModel(
    sub: subServers,
    dub: dubServers,
  );
}

List<ServerData> _extractServers(dom.Document document, String type) {
  return document
      .querySelectorAll('.server-item')
      .where((value) => value.attributes['data-type'] == type)
      .map((value) {
    return ServerData(
      name: value.querySelector('a')?.text,
      id: value.attributes['data-id'],
    );
  }).toList();
}

int? _parseNumber(String? text) => text != null ? int.tryParse(text) : null;
