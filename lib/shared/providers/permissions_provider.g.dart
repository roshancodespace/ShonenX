// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Permissions)
const permissionsProvider = PermissionsProvider._();

final class PermissionsProvider
    extends $NotifierProvider<Permissions, PermissionState> {
  const PermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionsHash();

  @$internal
  @override
  Permissions create() => Permissions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermissionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermissionState>(value),
    );
  }
}

String _$permissionsHash() => r'65f91ab9362714aeb852f46ae2d3d428ce199e55';

abstract class _$Permissions extends $Notifier<PermissionState> {
  PermissionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<PermissionState, PermissionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PermissionState, PermissionState>,
              PermissionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
