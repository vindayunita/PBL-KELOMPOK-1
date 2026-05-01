// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_application_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerApplicationRepository)
const sellerApplicationRepositoryProvider =
    SellerApplicationRepositoryProvider._();

final class SellerApplicationRepositoryProvider
    extends
        $FunctionalProvider<
          SellerApplicationRepository,
          SellerApplicationRepository,
          SellerApplicationRepository
        >
    with $Provider<SellerApplicationRepository> {
  const SellerApplicationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerApplicationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerApplicationRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerApplicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerApplicationRepository create(Ref ref) {
    return sellerApplicationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerApplicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerApplicationRepository>(value),
    );
  }
}

String _$sellerApplicationRepositoryHash() =>
    r'13540aa9f042316346f8d745903ec515b539b1e2';
