// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_application_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(courierApplicationRepository)
const courierApplicationRepositoryProvider =
    CourierApplicationRepositoryProvider._();

final class CourierApplicationRepositoryProvider
    extends
        $FunctionalProvider<
          CourierApplicationRepository,
          CourierApplicationRepository,
          CourierApplicationRepository
        >
    with $Provider<CourierApplicationRepository> {
  const CourierApplicationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierApplicationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierApplicationRepositoryHash();

  @$internal
  @override
  $ProviderElement<CourierApplicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CourierApplicationRepository create(Ref ref) {
    return courierApplicationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourierApplicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourierApplicationRepository>(value),
    );
  }
}

String _$courierApplicationRepositoryHash() =>
    r'b7f8ac4b9e02d255bf01584a6f8e879757ebf8a4';

@ProviderFor(courierApplicationByUid)
const courierApplicationByUidProvider = CourierApplicationByUidFamily._();

final class CourierApplicationByUidProvider
    extends
        $FunctionalProvider<
          AsyncValue<CourierApplicationModel?>,
          CourierApplicationModel?,
          Stream<CourierApplicationModel?>
        >
    with
        $FutureModifier<CourierApplicationModel?>,
        $StreamProvider<CourierApplicationModel?> {
  const CourierApplicationByUidProvider._({
    required CourierApplicationByUidFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courierApplicationByUidProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courierApplicationByUidHash();

  @override
  String toString() {
    return r'courierApplicationByUidProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CourierApplicationModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CourierApplicationModel?> create(Ref ref) {
    final argument = this.argument as String;
    return courierApplicationByUid(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourierApplicationByUidProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courierApplicationByUidHash() =>
    r'43ffd307a574e3b35dfb48cb6f56987efb8f25e1';

final class CourierApplicationByUidFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CourierApplicationModel?>, String> {
  const CourierApplicationByUidFamily._()
    : super(
        retry: null,
        name: r'courierApplicationByUidProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CourierApplicationByUidProvider call(String uid) =>
      CourierApplicationByUidProvider._(argument: uid, from: this);

  @override
  String toString() => r'courierApplicationByUidProvider';
}
