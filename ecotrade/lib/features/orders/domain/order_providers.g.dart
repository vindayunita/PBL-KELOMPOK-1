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

String _$mySellerOrdersHash() => r'34fba19a85f4c7fea91e6f2df3ce5243b009b463';

/// Stream tugas aktif kurir yang sedang login

@ProviderFor(myCourierTasks)
const myCourierTasksProvider = MyCourierTasksProvider._();

/// Stream tugas aktif kurir yang sedang login

final class MyCourierTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream tugas aktif kurir yang sedang login
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

String _$myCourierTasksHash() => r'c5a650c201ad7bf8135f711f9eef6708be493674';

/// Stream tugas retur kurir yang sedang login (return_approved / return_picked_up)

@ProviderFor(myCourierReturnTasks)
const myCourierReturnTasksProvider = MyCourierReturnTasksProvider._();

/// Stream tugas retur kurir yang sedang login (return_approved / return_picked_up)

final class MyCourierReturnTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream tugas retur kurir yang sedang login (return_approved / return_picked_up)
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
    r'd1cc371dc3b9f19d148c96d72bdfcf068ccc53c1';

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
    r'c48b91540eb2ba8ab581beeacb7d838dea092e9d';

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
