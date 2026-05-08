// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cartRepository)
const cartRepositoryProvider = CartRepositoryProvider._();

final class CartRepositoryProvider
    extends $FunctionalProvider<CartRepository, CartRepository, CartRepository>
    with $Provider<CartRepository> {
  const CartRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartRepositoryHash();

  @$internal
  @override
  $ProviderElement<CartRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CartRepository create(Ref ref) {
    return cartRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CartRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CartRepository>(value),
    );
  }
}

String _$cartRepositoryHash() => r'0b9e95b9ac2d45f18fca4c360edaf9342348a5dd';

@ProviderFor(cartItems)
const cartItemsProvider = CartItemsProvider._();

final class CartItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CartItemModel>>,
          List<CartItemModel>,
          Stream<List<CartItemModel>>
        >
    with
        $FutureModifier<List<CartItemModel>>,
        $StreamProvider<List<CartItemModel>> {
  const CartItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<CartItemModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CartItemModel>> create(Ref ref) {
    return cartItems(ref);
  }
}

String _$cartItemsHash() => r'1ed5ac5369e0c55be6706c95c95acc3b30c43868';
