// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentUserDoc)
const currentUserDocProvider = CurrentUserDocProvider._();

final class CurrentUserDocProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserModel?>,
          UserModel?,
          Stream<UserModel?>
        >
    with $FutureModifier<UserModel?>, $StreamProvider<UserModel?> {
  const CurrentUserDocProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserDocProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserDocHash();

  @$internal
  @override
  $StreamProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<UserModel?> create(Ref ref) {
    return currentUserDoc(ref);
  }
}

String _$currentUserDocHash() => r'6c8c8f4e7829c34e8255a997bbddf3943915cdd9';

@ProviderFor(userRoles)
const userRolesProvider = UserRolesProvider._();

final class UserRolesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const UserRolesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRolesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRolesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return userRoles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$userRolesHash() => r'2e4daa5bfbebcabed161bc38b055b4c51add06a7';

@ProviderFor(activeRole)
const activeRoleProvider = ActiveRoleProvider._();

final class ActiveRoleProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  const ActiveRoleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRoleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRoleHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return activeRole(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$activeRoleHash() => r'4c6e9acfbaf03c9e4bba55a7a106546264f1f25b';
