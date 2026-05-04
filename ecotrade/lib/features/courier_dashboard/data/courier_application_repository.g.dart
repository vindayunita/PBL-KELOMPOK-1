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
