import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferredScanlatorNotifier extends Notifier<String?> {
  final String mangaId;

  PreferredScanlatorNotifier(this.mangaId);

  @override
  String? build() {
    return null;
  }

  void setPreferred(String scanlator) {
    state = scanlator;
  }
}

final preferredScanlatorProvider =
    NotifierProvider.family<PreferredScanlatorNotifier, String?, String>(
      PreferredScanlatorNotifier.new,
    );
