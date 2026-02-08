// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WatchController)
const watchControllerProvider = WatchControllerProvider._();

final class WatchControllerProvider
    extends $NotifierProvider<WatchController, void> {
  const WatchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchControllerHash();

  @$internal
  @override
  WatchController create() => WatchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$watchControllerHash() => r'e1f4861b3b3409dbb41708d93cca3f87c549c279';

abstract class _$WatchController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
