// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_order_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminOrderRepository)
const adminOrderRepositoryProvider = AdminOrderRepositoryProvider._();

final class AdminOrderRepositoryProvider
    extends
        $FunctionalProvider<
          AdminOrderRepository,
          AdminOrderRepository,
          AdminOrderRepository
        >
    with $Provider<AdminOrderRepository> {
  const AdminOrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminOrderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminOrderRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminOrderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminOrderRepository create(Ref ref) {
    return adminOrderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminOrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminOrderRepository>(value),
    );
  }
}

String _$adminOrderRepositoryHash() =>
    r'21af240d82a6be6738df63120e22838d67b095e2';

/// Stream semua orders untuk admin (dengan filter status opsional).

@ProviderFor(allOrdersStream)
const allOrdersStreamProvider = AllOrdersStreamFamily._();

/// Stream semua orders untuk admin (dengan filter status opsional).

final class AllOrdersStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream semua orders untuk admin (dengan filter status opsional).
  const AllOrdersStreamProvider._({
    required AllOrdersStreamFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'allOrdersStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allOrdersStreamHash();

  @override
  String toString() {
    return r'allOrdersStreamProvider'
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
    final argument = this.argument as String?;
    return allOrdersStream(ref, status: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AllOrdersStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allOrdersStreamHash() => r'c62ba08dc68156f78f302b1fbd83cd80a30c05b3';

/// Stream semua orders untuk admin (dengan filter status opsional).

final class AllOrdersStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<OrderModel>>, String?> {
  const AllOrdersStreamFamily._()
    : super(
        retry: null,
        name: r'allOrdersStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream semua orders untuk admin (dengan filter status opsional).

  AllOrdersStreamProvider call({String? status}) =>
      AllOrdersStreamProvider._(argument: status, from: this);

  @override
  String toString() => r'allOrdersStreamProvider';
}

/// Stream order yang sudah diproses admin:
/// mencakup verified, processing, dan completed.

@ProviderFor(verifiedGroupOrdersStream)
const verifiedGroupOrdersStreamProvider = VerifiedGroupOrdersStreamProvider._();

/// Stream order yang sudah diproses admin:
/// mencakup verified, processing, dan completed.

final class VerifiedGroupOrdersStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  /// Stream order yang sudah diproses admin:
  /// mencakup verified, processing, dan completed.
  const VerifiedGroupOrdersStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifiedGroupOrdersStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifiedGroupOrdersStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return verifiedGroupOrdersStream(ref);
  }
}

String _$verifiedGroupOrdersStreamHash() =>
    r'dec6b1350e80f98a4bc5f8dd07d54db5cd55424d';
