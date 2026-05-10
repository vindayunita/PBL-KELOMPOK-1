// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_registration_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SellerRegistrationController)
const sellerRegistrationControllerProvider =
    SellerRegistrationControllerProvider._();

final class SellerRegistrationControllerProvider
    extends $AsyncNotifierProvider<SellerRegistrationController, void> {
  const SellerRegistrationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerRegistrationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerRegistrationControllerHash();

  @$internal
  @override
  SellerRegistrationController create() => SellerRegistrationController();
}

String _$sellerRegistrationControllerHash() =>
    r'1b7c38471586e086397be24372e1aa1b7fcd6e8a';

abstract class _$SellerRegistrationController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
