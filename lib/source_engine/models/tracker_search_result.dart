import 'package:shonenx/shared/models/unified_media.dart';

class TrackerSearchResult {
  final String id;
  final MediaTitle title;
  final String? cover;

  TrackerSearchResult({required this.id, required this.title, this.cover});
}
