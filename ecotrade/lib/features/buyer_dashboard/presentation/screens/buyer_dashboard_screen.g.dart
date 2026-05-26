// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buyer_dashboard_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Raw stream of all active products from Firestore

@ProviderFor(marketListings)
const marketListingsProvider = MarketListingsProvider._();

/// Raw stream of all active products from Firestore

final class MarketListingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductListing>>,
          List<ProductListing>,
          Stream<List<ProductListing>>
        >
    with
        $FutureModifier<List<ProductListing>>,
        $StreamProvider<List<ProductListing>> {
  /// Raw stream of all active products from Firestore
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
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProductListing>> create(Ref ref) {
    return marketListings(ref);
  }
}

String _$marketListingsHash() => r'b32df5b6e4f572e3ba00713c28c50ad3777b7159';
