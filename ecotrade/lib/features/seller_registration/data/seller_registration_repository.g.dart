// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_registration_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerRegistrationRepository)
const sellerRegistrationRepositoryProvider =
    SellerRegistrationRepositoryProvider._();

final class SellerRegistrationRepositoryProvider
    extends
        $FunctionalProvider<
          SellerRegistrationRepository,
          SellerRegistrationRepository,
          SellerRegistrationRepository
        >
    with $Provider<SellerRegistrationRepository> {
  const SellerRegistrationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerRegistrationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerRegistrationRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerRegistrationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerRegistrationRepository create(Ref ref) {
    return sellerRegistrationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerRegistrationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerRegistrationRepository>(value),
    );
  }
}

String _$sellerRegistrationRepositoryHash() =>
    r'4b07b62d311dd250bcde544b8d4a13278a7a38e4';
