// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payout_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(payoutRepository)
const payoutRepositoryProvider = PayoutRepositoryProvider._();

final class PayoutRepositoryProvider
    extends
        $FunctionalProvider<
          PayoutRepository,
          PayoutRepository,
          PayoutRepository
        >
    with $Provider<PayoutRepository> {
  const PayoutRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'payoutRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$payoutRepositoryHash();

  @$internal
  @override
  $ProviderElement<PayoutRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PayoutRepository create(Ref ref) {
    return payoutRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PayoutRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PayoutRepository>(value),
    );
  }
}

String _$payoutRepositoryHash() => r'e917f95e3ec640639bcc0c44198384baf28254bd';
