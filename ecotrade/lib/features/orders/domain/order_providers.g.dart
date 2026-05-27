// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream orders milik seller yang sedang login

@ProviderFor(mySellerOrders)
const mySellerOrdersProvider = MySellerOrdersProvider._();

/// Stream orders milik seller yang sedang login

final class MySellerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream orders milik seller yang sedang login
  const MySellerOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySellerOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mySellerOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return mySellerOrders(ref);
  }
}

String _$mySellerOrdersHash() => r'7925c938e8af3fd4bc271e368ee4807a4823700f';

/// Stream SEMUA tugas kurir yang sedang login (tanpa filter status)
/// Filter dilakukan di UI untuk fleksibilitas

@ProviderFor(myCourierTasks)
const myCourierTasksProvider = MyCourierTasksProvider._();

/// Stream SEMUA tugas kurir yang sedang login (tanpa filter status)
/// Filter dilakukan di UI untuk fleksibilitas

final class MyCourierTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream SEMUA tugas kurir yang sedang login (tanpa filter status)
  /// Filter dilakukan di UI untuk fleksibilitas
  const MyCourierTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCourierTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCourierTasksHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return myCourierTasks(ref);
  }
}

String _$myCourierTasksHash() => r'f543425ade32e8d3a4285040c0e9fc647f1ca6f3';

/// Stream tugas retur kurir yang sedang login

@ProviderFor(myCourierReturnTasks)
const myCourierReturnTasksProvider = MyCourierReturnTasksProvider._();

/// Stream tugas retur kurir yang sedang login

final class MyCourierReturnTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream tugas retur kurir yang sedang login
  const MyCourierReturnTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCourierReturnTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCourierReturnTasksHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return myCourierReturnTasks(ref);
  }
}

String _$myCourierReturnTasksHash() =>
    r'5721529da86dfd16c9b9ff24bf4d095294778b21';

/// Stream tugas retur SELESAI kurir yang sedang login

@ProviderFor(myCourierHistoryReturnTasks)
const myCourierHistoryReturnTasksProvider =
    MyCourierHistoryReturnTasksProvider._();

/// Stream tugas retur SELESAI kurir yang sedang login

final class MyCourierHistoryReturnTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream tugas retur SELESAI kurir yang sedang login
  const MyCourierHistoryReturnTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCourierHistoryReturnTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCourierHistoryReturnTasksHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return myCourierHistoryReturnTasks(ref);
  }
}

String _$myCourierHistoryReturnTasksHash() =>
    r'c4f8468b29909fd261d04b0858e9c8bd5fe2679a';

/// Stream orders berdasarkan status (untuk admin)

@ProviderFor(ordersByStatus)
const ordersByStatusProvider = OrdersByStatusFamily._();

/// Stream orders berdasarkan status (untuk admin)

final class OrdersByStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream orders berdasarkan status (untuk admin)
  const OrdersByStatusProvider._({
    required OrdersByStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ordersByStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ordersByStatusHash();

  @override
  String toString() {
    return r'ordersByStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    final argument = this.argument as String;
    return ordersByStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrdersByStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ordersByStatusHash() => r'6a938f809dfb0c01f26d6304d8d26293562a55fa';

/// Stream orders berdasarkan status (untuk admin)

final class OrdersByStatusFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<OrderModel>>, String> {
  const OrdersByStatusFamily._()
    : super(
        retry: null,
        name: r'ordersByStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream orders berdasarkan status (untuk admin)

  OrdersByStatusProvider call(String status) =>
      OrdersByStatusProvider._(argument: status, from: this);

  @override
  String toString() => r'ordersByStatusProvider';
}
