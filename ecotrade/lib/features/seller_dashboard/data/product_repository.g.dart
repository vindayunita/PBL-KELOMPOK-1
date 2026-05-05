// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productRepository)
const productRepositoryProvider = ProductRepositoryProvider._();

final class ProductRepositoryProvider
    extends
        $FunctionalProvider<
          ProductRepository,
          ProductRepository,
          ProductRepository
        >
    with $Provider<ProductRepository> {
  const ProductRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductRepository create(Ref ref) {
    return productRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRepository>(value),
    );
  }
}

String _$productRepositoryHash() => r'2c77d8a753d65f446b05004f8c4e2ae5eec01d35';

/// Stream produk milik seller yang sedang login

@ProviderFor(myProducts)
const myProductsProvider = MyProductsProvider._();

/// Stream produk milik seller yang sedang login

final class MyProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductModel>>,
          List<ProductModel>,
          Stream<List<ProductModel>>
        >
    with
        $FutureModifier<List<ProductModel>>,
        $StreamProvider<List<ProductModel>> {
  /// Stream produk milik seller yang sedang login
  const MyProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProductsHash();

  @$internal
  @override
  $StreamProviderElement<List<ProductModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProductModel>> create(Ref ref) {
    return myProducts(ref);
  }
}

String _$myProductsHash() => r'708e1dc6056cb6b7f35634731eb5fa2a35107b34';
