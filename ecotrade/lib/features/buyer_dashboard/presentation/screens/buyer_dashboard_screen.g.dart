// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buyer_dashboard_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(marketListings)
const marketListingsProvider = MarketListingsProvider._();

final class MarketListingsProvider extends $FunctionalProvider<
        AsyncValue<List<ProductListing>>,
        List<ProductListing>,
        Stream<List<ProductListing>>>
    with
        $FutureModifier<List<ProductListing>>,
        $StreamProvider<List<ProductListing>> {
  const MarketListingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'marketListingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketListingsHash();

  @$internal
  @override
  $StreamProviderElement<List<ProductListing>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ProductListing>> create(Ref ref) {
    return marketListings(ref);
  }
}

String _$marketListingsHash() => r'b25c6c658a64a62e32c713854899590d379453e2';
