// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_sync_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WatchSyncNotifier)
const watchSyncProvider = WatchSyncNotifierProvider._();

final class WatchSyncNotifierProvider
    extends $NotifierProvider<WatchSyncNotifier, void> {
  const WatchSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchSyncNotifierHash();

  @$internal
  @override
  WatchSyncNotifier create() => WatchSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$watchSyncNotifierHash() => r'd4bca5826746f55693c7c2c4877073a76f11d9e5';

abstract class _$WatchSyncNotifier extends $Notifier<void> {
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
