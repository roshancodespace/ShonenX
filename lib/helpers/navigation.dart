import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';

void navigateToDetail(BuildContext context, Media media, String tag) {
  context.push('/details?tag=$tag', extra: media);
}
