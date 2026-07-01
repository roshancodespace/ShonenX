import 'dart:convert';

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
    if (input is Map && input['__type'] == 'ComplexExtra') {
      return _ComplexExtraCache.instance.get(input['id'] as String);
    }
    return input;
  }
}

class _ComplexExtraEncoder extends Converter<Object?, Object?> {
  const _ComplexExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null || input is num || input is String || input is bool) {
      return input;
    }
    final id = _ComplexExtraCache.instance.put(input);
    return {'__type': 'ComplexExtra', 'id': id};
  }
}

class _ComplexExtraCache {
  _ComplexExtraCache._();
  static final instance = _ComplexExtraCache._();
  final Map<String, Object> _cache = {};
  int _counter = 0;

  String put(Object object) {
    final id = 'extra_${_counter++}_${object.hashCode}';
    _cache[id] = object;
    return id;
  }

  Object? get(String id) {
    return _cache[id];
  }
}
