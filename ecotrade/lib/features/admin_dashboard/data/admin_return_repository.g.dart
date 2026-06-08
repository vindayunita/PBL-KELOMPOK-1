// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_return_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminReturnRepository)
const adminReturnRepositoryProvider = AdminReturnRepositoryProvider._();

final class AdminReturnRepositoryProvider
    extends
        $FunctionalProvider<
          AdminReturnRepository,
          AdminReturnRepository,
          AdminReturnRepository
        >
    with $Provider<AdminReturnRepository> {
  const AdminReturnRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminReturnRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminReturnRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminReturnRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminReturnRepository create(Ref ref) {
    return adminReturnRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminReturnRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminReturnRepository>(value),
    );
  }
}

String _$adminReturnRepositoryHash() =>
    r'7645d1446047ad0e5cd0328f2c181893570f49e3';

/// Stream semua return requests, difilter berdasarkan status (null = semua).

@ProviderFor(allReturnRequestsStream)
const allReturnRequestsStreamProvider = AllReturnRequestsStreamFamily._();

/// Stream semua return requests, difilter berdasarkan status (null = semua).

final class AllReturnRequestsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReturnModel>>,
          List<ReturnModel>,
          Stream<List<ReturnModel>>
        >
    with
        $FutureModifier<List<ReturnModel>>,
        $StreamProvider<List<ReturnModel>> {
  /// Stream semua return requests, difilter berdasarkan status (null = semua).
  const AllReturnRequestsStreamProvider._({
    required AllReturnRequestsStreamFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'allReturnRequestsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allReturnRequestsStreamHash();

  @override
  String toString() {
    return r'allReturnRequestsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ReturnModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReturnModel>> create(Ref ref) {
    final argument = this.argument as String?;
    return allReturnRequestsStream(ref, status: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AllReturnRequestsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allReturnRequestsStreamHash() =>
    r'd50422bfac98eff2d0caa3fee36b8efd201c9c67';

/// Stream semua return requests, difilter berdasarkan status (null = semua).

final class AllReturnRequestsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ReturnModel>>, String?> {
  const AllReturnRequestsStreamFamily._()
    : super(
        retry: null,
        name: r'allReturnRequestsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream semua return requests, difilter berdasarkan status (null = semua).

  AllReturnRequestsStreamProvider call({String? status}) =>
      AllReturnRequestsStreamProvider._(argument: status, from: this);

  @override
  String toString() => r'allReturnRequestsStreamProvider';
}
