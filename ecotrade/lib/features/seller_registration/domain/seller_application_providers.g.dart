// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_application_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watch status aplikasi seller milik user yang sedang login (real-time).

@ProviderFor(mySellerApplication)
const mySellerApplicationProvider = MySellerApplicationProvider._();

/// Watch status aplikasi seller milik user yang sedang login (real-time).

final class MySellerApplicationProvider
    extends
        $FunctionalProvider<
          AsyncValue<SellerApplicationModel?>,
          SellerApplicationModel?,
          Stream<SellerApplicationModel?>
        >
    with
        $FutureModifier<SellerApplicationModel?>,
        $StreamProvider<SellerApplicationModel?> {
  /// Watch status aplikasi seller milik user yang sedang login (real-time).
  const MySellerApplicationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySellerApplicationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mySellerApplicationHash();

  @$internal
  @override
  $StreamProviderElement<SellerApplicationModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SellerApplicationModel?> create(Ref ref) {
    return mySellerApplication(ref);
  }
}

String _$mySellerApplicationHash() =>
    r'4a4c45121dfa20c7a34d9a086ceb93b48b5c4c53';

/// Watch semua aplikasi (untuk admin), difilter berdasarkan status.

@ProviderFor(allSellerApplications)
const allSellerApplicationsProvider = AllSellerApplicationsFamily._();

/// Watch semua aplikasi (untuk admin), difilter berdasarkan status.

final class AllSellerApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerApplicationModel>>,
          List<SellerApplicationModel>,
          Stream<List<SellerApplicationModel>>
        >
    with
        $FutureModifier<List<SellerApplicationModel>>,
        $StreamProvider<List<SellerApplicationModel>> {
  /// Watch semua aplikasi (untuk admin), difilter berdasarkan status.
  const AllSellerApplicationsProvider._({
    required AllSellerApplicationsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'allSellerApplicationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allSellerApplicationsHash();

  @override
  String toString() {
    return r'allSellerApplicationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SellerApplicationModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SellerApplicationModel>> create(Ref ref) {
    final argument = this.argument as String?;
    return allSellerApplications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AllSellerApplicationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allSellerApplicationsHash() =>
    r'4c3fcc958fedfa0b3a931115d2064e20a1aac51f';

/// Watch semua aplikasi (untuk admin), difilter berdasarkan status.

final class AllSellerApplicationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<SellerApplicationModel>>,
          String?
        > {
  const AllSellerApplicationsFamily._()
    : super(
        retry: null,
        name: r'allSellerApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watch semua aplikasi (untuk admin), difilter berdasarkan status.

  AllSellerApplicationsProvider call(String? status) =>
      AllSellerApplicationsProvider._(argument: status, from: this);

  @override
  String toString() => r'allSellerApplicationsProvider';
}
