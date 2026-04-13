// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initialization_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Initialization)
const initializationProvider = InitializationProvider._();

final class InitializationProvider
    extends $NotifierProvider<Initialization, InitializationState> {
  const InitializationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initializationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initializationHash();

  @$internal
  @override
  Initialization create() => Initialization();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InitializationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InitializationState>(value),
    );
  }
}

String _$initializationHash() => r'c060b65b7eff1ebae16aaf94b9cd2921d7199d94';

abstract class _$Initialization extends $Notifier<InitializationState> {
  InitializationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<InitializationState, InitializationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InitializationState, InitializationState>,
              InitializationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
