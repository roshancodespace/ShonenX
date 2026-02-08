// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SourceNotifier)
const sourceProvider = SourceNotifierProvider._();

final class SourceNotifierProvider
    extends $NotifierProvider<SourceNotifier, SourceState> {
  const SourceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceNotifierHash();

  @$internal
  @override
  SourceNotifier create() => SourceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceState>(value),
    );
  }
}

String _$sourceNotifierHash() => r'f398da3d693396e851ced20174db39784ef5b086';

abstract class _$SourceNotifier extends $Notifier<SourceState> {
  SourceState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SourceState, SourceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SourceState, SourceState>,
              SourceState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
