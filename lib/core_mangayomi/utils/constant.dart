import 'package:flutter/material.dart';
import 'package:shonenx/core_mangayomi/models/manga.dart';
import 'package:shonenx/core_mangayomi/models/track.dart';

const defaultUserAgent =
    "Mozilla/5.0 (Linux; Android 13; 22081212UG Build/TKQ1.220829.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.131 Mobile Safari/537.36";

String getMangaStatusName(Status status) {
  return switch (status) {
    Status.ongoing => "Ongoing",
    Status.onHiatus => "On Hiatus",
    Status.canceled => "Canceled",
    Status.completed => "Completed",
    Status.publishingFinished => "Publishing Finished",
    _ => "Unknown",
  };
}

IconData getMangaStatusIcon(Status status) {
  return switch (status) {
    Status.ongoing => Icons.schedule_rounded,
    Status.onHiatus => Icons.pause_circle_rounded,
    Status.canceled => Icons.cancel_rounded,
    Status.completed => Icons.done_all_outlined,
    Status.publishingFinished => Icons.done,
    _ => Icons.block_outlined,
  };
}

String getTrackStatus(TrackStatus status) {
  return switch (status) {
    TrackStatus.watching => "Watching",
    TrackStatus.reWatching => "Rewatching",
    TrackStatus.planToWatch => "Plan to Watch",
    TrackStatus.reading => "Reading",
    TrackStatus.completed => "Completed",
    TrackStatus.onHold => "On Hold",
    TrackStatus.dropped => "Dropped",
    TrackStatus.planToRead => "Plan to Read",
    TrackStatus.reReading => "Rereading",
  };
}

TrackStatus toTrackStatus(TrackStatus status, ItemType itemType, int syncId) {
  return itemType == ItemType.anime && syncId == 2
      ? switch (status) {
          TrackStatus.reading => TrackStatus.watching,
          TrackStatus.planToRead => TrackStatus.planToWatch,
          TrackStatus.reReading => TrackStatus.reWatching,
          _ => status,
        }
      : status;
}

(String, String, Color) trackInfos(int id) {
  return switch (id) {
    1 => (
      "assets/trackers_icons/tracker_mal.webp",
      "MyAnimeList",
      const Color.fromRGBO(46, 81, 162, 1),
    ),
    2 => (
      "assets/trackers_icons/tracker_anilist.webp",
      "Anilist",
      const Color.fromRGBO(51, 37, 50, 1),
    ),
    _ => (
      "assets/trackers_icons/tracker_kitsu.webp",
      "Kitsu",
      const Color.fromRGBO(18, 25, 35, 1),
    ),
  };
}

String toImgUrl(String url) {
  return url.isEmpty ? _emptyImg : url;
}

const _emptyImg =
    "https://upload.wikimedia.org/wikipedia/commons/1/12/White_background.png";
