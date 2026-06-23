import 'dart:convert';

import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class ComplexExtraCodec extends Codec<Object?, Object?> {
  const ComplexExtraCodec();

  @override
  Converter<Object?, Object?> get decoder => const _ComplexExtraDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _ComplexExtraEncoder();
}

class _ComplexExtraDecoder extends Converter<Object?, Object?> {
  const _ComplexExtraDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is Map<String, dynamic> && input['__type'] == 'ComplexExtra') {
      return _ComplexExtraCache.instance.get(input['id'] as String);
    }
    return input;
  }
}

class _ComplexExtraEncoder extends Converter<Object?, Object?> {
  const _ComplexExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is UnifiedMedia || input is PlayerMode || input is ReaderMode) {
      final id = _ComplexExtraCache.instance.put(input);
      return {'__type': 'ComplexExtra', 'id': id};
    }
    return input;
  }
}

class _ComplexExtraCache {
  _ComplexExtraCache._();
  static final instance = _ComplexExtraCache._();
  final Map<String, Object> _cache = {};

  String put(Object object) {
    final id = object.hashCode.toString();
    _cache[id] = object;
    return id;
  }

  Object? get(String id) {
    return _cache[id];
  }
}
