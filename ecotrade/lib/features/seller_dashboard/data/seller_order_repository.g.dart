// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_order_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerOrderRepository)
const sellerOrderRepositoryProvider = SellerOrderRepositoryProvider._();

final class SellerOrderRepositoryProvider
    extends
        $FunctionalProvider<
          SellerOrderRepository,
          SellerOrderRepository,
          SellerOrderRepository
        >
    with $Provider<SellerOrderRepository> {
  const SellerOrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerOrderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerOrderRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerOrderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerOrderRepository create(Ref ref) {
    return sellerOrderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerOrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerOrderRepository>(value),
    );
  }
}

String _$sellerOrderRepositoryHash() =>
    r'4f6c8cc4c698b3237b2d6516aaf9c75b6eda1477';

/// Stream order "masuk" untuk seller yang sedang login.
/// Menampilkan order yang sudah diverifikasi admin (status = 'verified')
/// dan sedang diproses (status = 'processing').

@ProviderFor(sellerIncomingOrders)
const sellerIncomingOrdersProvider = SellerIncomingOrdersProvider._();

/// Stream order "masuk" untuk seller yang sedang login.
/// Menampilkan order yang sudah diverifikasi admin (status = 'verified')
/// dan sedang diproses (status = 'processing').

final class SellerIncomingOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream order "masuk" untuk seller yang sedang login.
  /// Menampilkan order yang sudah diverifikasi admin (status = 'verified')
  /// dan sedang diproses (status = 'processing').
  const SellerIncomingOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerIncomingOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerIncomingOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return sellerIncomingOrders(ref);
  }
}

String _$sellerIncomingOrdersHash() =>
    r'c41e8b1315cec5d69cd456acc6f9e77dc5286b40';

/// Stream order yang sudah selesai (completed) milik seller ini.

@ProviderFor(sellerCompletedOrders)
const sellerCompletedOrdersProvider = SellerCompletedOrdersProvider._();

/// Stream order yang sudah selesai (completed) milik seller ini.

final class SellerCompletedOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream order yang sudah selesai (completed) milik seller ini.
  const SellerCompletedOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerCompletedOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerCompletedOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return sellerCompletedOrders(ref);
  }
}

String _$sellerCompletedOrdersHash() =>
    r'97a3092a175305fbe27abe58ebbf73e50cc00be5';

/// Stream return request untuk seller ini.

@ProviderFor(sellerReturnOrders)
const sellerReturnOrdersProvider = SellerReturnOrdersProvider._();

/// Stream return request untuk seller ini.

final class SellerReturnOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream return request untuk seller ini.
  const SellerReturnOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerReturnOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerReturnOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return sellerReturnOrders(ref);
  }
}

String _$sellerReturnOrdersHash() =>
    r'23fcb6547c00643ad623189e51cc74dc32544418';
