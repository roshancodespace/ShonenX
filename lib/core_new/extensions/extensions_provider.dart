import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core_new/models/manga.dart';
import 'package:shonenx/core_new/models/source.dart';

import 'package:shonenx/main.dart';

part 'extensions_provider.g.dart';

@riverpod
Stream<List<Source>> getExtensionsStream(
    GetExtensionsStreamRef ref, ItemType itemType) async* {
  yield* isar.sources
      .filter()
      .idIsNotNull()
      .and()
      .isActiveEqualTo(true)
      .itemTypeEqualTo(itemType)
      .watch(fireImmediately: true);
}
