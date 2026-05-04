// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_application_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watch status aplikasi kurir milik user yang sedang login (real-time).

@ProviderFor(myCourierApplication)
const myCourierApplicationProvider = MyCourierApplicationProvider._();

/// Watch status aplikasi kurir milik user yang sedang login (real-time).

final class MyCourierApplicationProvider
    extends
        $FunctionalProvider<
          AsyncValue<CourierApplicationModel?>,
          CourierApplicationModel?,
          Stream<CourierApplicationModel?>
        >
    with
        $FutureModifier<CourierApplicationModel?>,
        $StreamProvider<CourierApplicationModel?> {
  /// Watch status aplikasi kurir milik user yang sedang login (real-time).
  const MyCourierApplicationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCourierApplicationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCourierApplicationHash();

  @$internal
  @override
  $StreamProviderElement<CourierApplicationModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CourierApplicationModel?> create(Ref ref) {
    return myCourierApplication(ref);
  }
}

String _$myCourierApplicationHash() =>
    r'403bb0d26bb2994e876776fced630a2a889f925c';

/// Watch semua aplikasi kurir (untuk admin), difilter berdasarkan status.

@ProviderFor(allCourierApplications)
const allCourierApplicationsProvider = AllCourierApplicationsFamily._();

/// Watch semua aplikasi kurir (untuk admin), difilter berdasarkan status.

final class AllCourierApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourierApplicationModel>>,
          List<CourierApplicationModel>,
          Stream<List<CourierApplicationModel>>
        >
    with
        $FutureModifier<List<CourierApplicationModel>>,
        $StreamProvider<List<CourierApplicationModel>> {
  /// Watch semua aplikasi kurir (untuk admin), difilter berdasarkan status.
  const AllCourierApplicationsProvider._({
    required AllCourierApplicationsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'allCourierApplicationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allCourierApplicationsHash();

  @override
  String toString() {
    return r'allCourierApplicationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CourierApplicationModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CourierApplicationModel>> create(Ref ref) {
    final argument = this.argument as String?;
    return allCourierApplications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AllCourierApplicationsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allCourierApplicationsHash() =>
    r'77c86aa739f69b911372a3603f4f5593804be2ad';

/// Watch semua aplikasi kurir (untuk admin), difilter berdasarkan status.

final class AllCourierApplicationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<CourierApplicationModel>>,
          String?
        > {
  const AllCourierApplicationsFamily._()
    : super(
        retry: null,
        name: r'allCourierApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watch semua aplikasi kurir (untuk admin), difilter berdasarkan status.

  AllCourierApplicationsProvider call(String? status) =>
      AllCourierApplicationsProvider._(argument: status, from: this);

  @override
  String toString() => r'allCourierApplicationsProvider';
}
