import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/widgets/notification_badge.dart';
import '../../../seller_dashboard/domain/product_model.dart';
import 'buyer_order_screen.dart';
import 'buyer_profile_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

part 'buyer_dashboard_screen.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class ProductListing {
  const ProductListing({
    required this.id,
    required this.title,
    required this.price,
    required this.unit,
    required this.badge,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.sellerCity = 'Malang',
    this.commodityType = '',
    this.stock = 0,
    this.description = '',
  });

  final String id;
  final String title;
  final double price;
  final String unit;
  final String badge;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String sellerCity;
  final String commodityType;
  final int stock;
  final String description;

  factory ProductListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductListing(
      id: doc.id,
      title: data['title'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? 'kg',
      badge: data['badge'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? '',
      sellerCity: data['sellerCity'] as String? ?? 'Malang',
      commodityType: data['commodityType'] as String? ?? '',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
    );
  }

  /// Convert to full ProductModel for the detail screen.
  ProductModel toProductModel() => ProductModel(
        id: id,
        title: title,
        description: description,
        commodityType: commodityType,
        price: price,
        unit: unit,
        stock: stock,
        badge: badge,
        imageUrl: imageUrl,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerCity: sellerCity,
        status: 'active',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter model
// ─────────────────────────────────────────────────────────────────────────────
class ProductFilter {
  const ProductFilter({
    this.commodityTypes = const {},
    this.locations = const {},
    this.minPrice = 0,
    this.maxPrice = double.infinity,
    this.minRating = 0,
  });

  final Set<String> commodityTypes;
  final Set<String> locations;
  final double minPrice;
  final double maxPrice;
  final double minRating; // 0 = no filter, 1-5 = minimum stars

  bool get isActive =>
      commodityTypes.isNotEmpty ||
      locations.isNotEmpty ||
      minPrice > 0 ||
      maxPrice < double.infinity ||
      minRating > 0;

  int get activeCount {
    int count = 0;
    if (commodityTypes.isNotEmpty) count++;
    if (locations.isNotEmpty) count++;
    if (minPrice > 0 || maxPrice < double.infinity) count++;
    if (minRating > 0) count++;
    return count;
  }

  ProductFilter copyWith({
    Set<String>? commodityTypes,
    Set<String>? locations,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    return ProductFilter(
      commodityTypes: commodityTypes ?? this.commodityTypes,
      locations: locations ?? this.locations,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier for bottom nav index
class BuyerNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void updateIndex(int index) => state = index;
}

final buyerNavIndexProvider = NotifierProvider<BuyerNavIndexNotifier, int>(BuyerNavIndexNotifier.new);

/// Notifier for order screen tab index
class BuyerOrderTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void updateIndex(int index) => state = index;
}

final buyerOrderTabIndexProvider = NotifierProvider<BuyerOrderTabIndexNotifier, int>(BuyerOrderTabIndexNotifier.new);

/// Notifier for product filter state (Riverpod 3.x compatible)
class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void update(ProductFilter filter) => state = filter;

  void reset() => state = const ProductFilter();
}

/// Current active filter state
final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
  ProductFilterNotifier.new,
);

/// Notifier for search query state (Riverpod 3.x compatible)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// Search query state
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Average ratings per productId, computed from the reviews collection
final productAverageRatingsProvider =
    StreamProvider<Map<String, double>>((ref) {
  return FirebaseFirestore.instance.collection('reviews').snapshots().map(
    (snap) {
      final Map<String, List<int>> ratingsMap = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final productId = data['productId'] as String? ?? '';
        final rating = (data['rating'] as num?)?.toInt() ?? 0;
        if (productId.isNotEmpty) {
          ratingsMap.putIfAbsent(productId, () => []).add(rating);
        }
      }
      return ratingsMap.map(
        (id, ratings) => MapEntry(
          id,
          ratings.fold<double>(0, (sum, r) => sum + r) / ratings.length,
        ),
      );
    },
  );
});

/// Raw stream of all active products from Firestore
@riverpod
Stream<List<ProductListing>> marketListings(Ref ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map((snap) {
    final list = snap.docs.map(ProductListing.fromFirestore).toList();
    // Sort berdasarkan createdAt descending di sisi client
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  });
}

/// Filtered + searched product listings (derived provider)
final filteredListingsProvider = Provider<AsyncValue<List<ProductListing>>>(
  (ref) {
    final listingsAsync = ref.watch(marketListingsProvider);
    final ratingsAsync = ref.watch(productAverageRatingsProvider);
    final filter = ref.watch(productFilterProvider);
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();

    return listingsAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (listings) {
        final ratings = ratingsAsync.maybeWhen(
          data: (r) => r,
          orElse: () => <String, double>{},
        );

        final filtered = listings.where((p) {
          // Filter pencarian teks
          if (query.isNotEmpty) {
            final matchTitle = p.title.toLowerCase().contains(query);
            final matchCommodity =
                p.commodityType.toLowerCase().contains(query);
            final matchCity = p.sellerCity.toLowerCase().contains(query);
            if (!matchTitle && !matchCommodity && !matchCity) return false;
          }

          // Filter jenis komoditi
          if (filter.commodityTypes.isNotEmpty &&
              !filter.commodityTypes.contains(p.commodityType)) {
            return false;
          }

          // Filter lokasi penjual
          if (filter.locations.isNotEmpty &&
              !filter.locations.contains(p.sellerCity)) {
            return false;
          }

          // Filter rentang harga
          if (p.price < filter.minPrice) return false;
          if (filter.maxPrice < double.infinity &&
              p.price > filter.maxPrice) {
            return false;
          }

          // Filter penilaian minimum
          if (filter.minRating > 0) {
            final avgRating = ratings[p.id] ?? 0.0;
            if (avgRating < filter.minRating) return false;
          }

          return true;
        }).toList();

        return AsyncValue.data(filtered);
      },
    );
  },
);

/// Maximum price across all products (for slider upper bound)
final _maxPriceProvider = Provider<double>((ref) {
  final listings = ref.watch(marketListingsProvider).maybeWhen(
        data: (l) => l,
        orElse: () => <ProductListing>[],
      );
  if (listings.isEmpty) return 10000000;
  final maxVal =
      listings.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  // Round up ke kelipatan 100 ribu terdekat
  final rounded = ((maxVal / 100000).ceil() * 100000).toDouble();
  return rounded < 100000 ? 10000000 : rounded;
});

/// Daftar jenis komoditi tetap (hanya 5 kategori ini)
const _kPredefinedCommodityTypes = [
  'Serat Alami',
  'Biomassa & Energi',
  'Pupuk & Pertanian',
  'Bahan Industri',
  'Lainnya',
];

/// Jenis komoditi: hanya dari daftar tetap di atas
final _availableCommoditiesProvider = Provider<List<String>>(
  (_) => _kPredefinedCommodityTypes,
);

/// Daftar kota/kabupaten Jawa Timur (38 daerah)
const _kEastJavaCities = [
  // ── Kota ──────────────────────────────────────
  'Surabaya',
  'Malang',
  'Blitar',
  'Kediri',
  'Madiun',
  'Mojokerto',
  'Pasuruan',
  'Probolinggo',
  'Batu',
  // ── Kabupaten ─────────────────────────────────
  'Bangkalan',
  'Banyuwangi',
  'Kab. Blitar',
  'Bojonegoro',
  'Bondowoso',
  'Gresik',
  'Jember',
  'Jombang',
  'Kab. Kediri',
  'Lamongan',
  'Lumajang',
  'Kab. Madiun',
  'Magetan',
  'Kab. Malang',
  'Kab. Mojokerto',
  'Nganjuk',
  'Ngawi',
  'Pacitan',
  'Pamekasan',
  'Kab. Pasuruan',
  'Ponorogo',
  'Kab. Probolinggo',
  'Sampang',
  'Sidoarjo',
  'Situbondo',
  'Sumenep',
  'Trenggalek',
  'Tuban',
  'Tulungagung',
];

/// Lokasi penjual: gabungan kota Jawa Timur + data Firestore
final _availableLocationsProvider = Provider<List<String>>((ref) {
  final listings = ref.watch(marketListingsProvider).maybeWhen(
        data: (l) => l,
        orElse: () => <ProductListing>[],
      );
  // Mulai dari semua kota Jawa Timur
  final set = <String>{..._kEastJavaCities};
  // Tambahkan kota dari Firestore yang tidak ada di list
  for (final p in listings) {
    if (p.sellerCity.isNotEmpty) set.add(p.sellerCity);
  }
  // Kota Jawa Timur dulu (urutan asli), lalu extras dari Firestore
  final eastJava = _kEastJavaCities
      .where((c) => set.contains(c))
      .toList();
  final extras = set
      .where((c) => !_kEastJavaCities.contains(c))
      .toList()..sort();
  return [...eastJava, ...extras];
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen — shell with indexed body switching
// ─────────────────────────────────────────────────────────────────────────────
class BuyerDashboardScreen extends ConsumerStatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  ConsumerState<BuyerDashboardScreen> createState() =>
      _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState
    extends ConsumerState<BuyerDashboardScreen> {

  Widget _buildBody(int index) {
    switch (index) {
      case 1:
        return const BuyerOrderScreen();
      case 2:
        return const CartScreen();
      case 3:
        return const BuyerProfileScreen();
      default:
        return const _MarketPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedNavIndex = ref.watch(buyerNavIndexProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(child: _buildBody(selectedNavIndex)),
      bottomNavigationBar: _BottomNav(
        selectedIndex: selectedNavIndex,
        onTap: (i) {
          if (i == 1) {
            // Reset ke tab 'Semua' (0) jika menekan My Orders dari navbar
            ref.read(buyerOrderTabIndexProvider.notifier).updateIndex(0);
          }
          ref.read(buyerNavIndexProvider.notifier).updateIndex(i);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Market page
// ─────────────────────────────────────────────────────────────────────────────
class _MarketPage extends ConsumerStatefulWidget {
  const _MarketPage();

  @override
  ConsumerState<_MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<_MarketPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).update(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    final filter = ref.read(productFilterProvider);
    final maxPrice = ref.read(_maxPriceProvider);
    final commodities = ref.read(_availableCommoditiesProvider);
    final locations = ref.read(_availableLocationsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        currentFilter: filter,
        maxPossiblePrice: maxPrice,
        availableCommodities: commodities,
        availableLocations: locations,
        onApply: (newFilter) {
          ref.read(productFilterProvider.notifier).update(newFilter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filter = ref.watch(productFilterProvider);
    final activeCount = filter.activeCount;

    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────────────────────
        SliverAppBar(
          title: Text(
            'EcoTrade',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          actions: const [
            NotificationBadge(),
            SizedBox(width: 4),
          ],
        ),

        // ── Search + Filter ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Cari produk, komoditi, kota...',
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurface.withOpacity(0.5),
                          size: 22,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (_, value, __) => value.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded,
                                      size: 18,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.5)),
                                  onPressed: () => _searchController.clear(),
                                )
                              : const SizedBox.shrink(),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter button with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: activeCount > 0
                              ? colorScheme.primary.withOpacity(0.85)
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: activeCount > 0
                              ? [
                                  BoxShadow(
                                    color:
                                        colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    if (activeCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surfaceContainerLowest,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$activeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Active filter chips ───────────────────────────────────────────
        if (filter.isActive)
          SliverToBoxAdapter(
            child: _ActiveFilterChips(filter: filter),
          ),

        // ── Hero Banner ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HeroBanner(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── Market Listings header ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Listings',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        filter.isActive
                            ? 'Menampilkan hasil filter'
                            : 'Curated high-yield organic materials',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                if (filter.isActive)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(productFilterProvider.notifier).reset();
                    },
                    icon: Icon(Icons.filter_alt_off_rounded,
                        size: 14, color: Colors.red.shade400),
                    label: Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  )
                else
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Product grid ──────────────────────────────────────────────────
        const _ProductGrid(),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filter chips row
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveFilterChips extends ConsumerWidget {
  const _ActiveFilterChips({required this.filter});
  final ProductFilter filter;

  String _fmtPrice(double val) => val
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    for (final type in filter.commodityTypes) {
      chips.add(_FilterActiveChip(
        label: type,
        icon: Icons.category_rounded,
        onDelete: () {
          final updated = Set<String>.from(filter.commodityTypes)
            ..remove(type);
          ref.read(productFilterProvider.notifier).update(
              filter.copyWith(commodityTypes: updated));
        },
        cs: cs,
      ));
    }

    for (final loc in filter.locations) {
      chips.add(_FilterActiveChip(
        label: loc,
        icon: Icons.location_on_rounded,
        onDelete: () {
          final updated = Set<String>.from(filter.locations)..remove(loc);
          ref.read(productFilterProvider.notifier).update(
              filter.copyWith(locations: updated));
        },
        cs: cs,
      ));
    }

    if (filter.minPrice > 0 || filter.maxPrice < double.infinity) {
      final min = _fmtPrice(filter.minPrice);
      final maxLabel = filter.maxPrice < double.infinity
          ? 'Rp ${_fmtPrice(filter.maxPrice)}'
          : '∞';
      chips.add(_FilterActiveChip(
        label: 'Rp $min – $maxLabel',
        icon: Icons.payments_rounded,
        onDelete: () {
          ref.read(productFilterProvider.notifier).update(filter.copyWith(
            minPrice: 0,
            maxPrice: double.infinity,
          ));
        },
        cs: cs,
      ));
    }

    if (filter.minRating > 0) {
      chips.add(_FilterActiveChip(
        label: '≥ ${filter.minRating.toStringAsFixed(0)} Bintang',
        icon: Icons.star_rounded,
        iconColor: const Color(0xFFFFC107),
        onDelete: () {
          ref.read(productFilterProvider.notifier).update(
              filter.copyWith(minRating: 0));
        },
        cs: cs,
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: chips),
    );
  }
}

class _FilterActiveChip extends StatelessWidget {
  const _FilterActiveChip({
    required this.label,
    required this.icon,
    required this.onDelete,
    required this.cs,
    this.iconColor,
  });
  final String label;
  final IconData icon;
  final VoidCallback onDelete;
  final ColorScheme cs;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor ?? cs.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded,
                  size: 14, color: cs.onPrimaryContainer.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.currentFilter,
    required this.maxPossiblePrice,
    required this.availableCommodities,
    required this.availableLocations,
    required this.onApply,
  });

  final ProductFilter currentFilter;
  final double maxPossiblePrice;
  final List<String> availableCommodities;
  final List<String> availableLocations;
  final ValueChanged<ProductFilter> onApply;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<String> _selectedCommodities;
  late Set<String> _selectedLocations;
  late RangeValues _priceRange;
  late double _minRating;
  late double _effectiveMaxPrice;

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilter;
    _effectiveMaxPrice = widget.maxPossiblePrice < 10000
        ? 10000000
        : widget.maxPossiblePrice;

    _selectedCommodities = Set<String>.from(f.commodityTypes);
    _selectedLocations = Set<String>.from(f.locations);
    _priceRange = RangeValues(
      math.max(0, f.minPrice),
      f.maxPrice < double.infinity
          ? math.min(f.maxPrice, _effectiveMaxPrice)
          : _effectiveMaxPrice,
    );
    _minRating = f.minRating;
  }

  void _reset() {
    setState(() {
      _selectedCommodities = {};
      _selectedLocations = {};
      _priceRange = RangeValues(0, _effectiveMaxPrice);
      _minRating = 0;
    });
  }

  void _apply() {
    final newFilter = ProductFilter(
      commodityTypes: Set<String>.from(_selectedCommodities),
      locations: Set<String>.from(_selectedLocations),
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end >= _effectiveMaxPrice
          ? double.infinity
          : _priceRange.end,
      minRating: _minRating,
    );
    widget.onApply(newFilter);
    Navigator.of(context).pop();
  }

  String _fmtPrice(double val) => val
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 22, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  'Filter Produk',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'Reset Semua',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: cs.outlineVariant, height: 1),

          // ── Scrollable content ──────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Jenis Komoditi ──────────────────────────────────
                  _SheetSectionHeader(
                    icon: Icons.category_outlined,
                    label: 'Jenis Komoditi',
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 12),
                  if (widget.availableCommodities.isEmpty)
                    _EmptyChipHint(
                        text: 'Belum ada data komoditi', cs: cs, tt: tt)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availableCommodities.map((type) {
                        final isSelected =
                            _selectedCommodities.contains(type);
                        return _SelectableChip(
                          label: type,
                          isSelected: isSelected,
                          selectedColor: cs.primary,
                          selectedTextColor: cs.onPrimary,
                          cs: cs,
                          tt: tt,
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedCommodities.remove(type);
                            } else {
                              _selectedCommodities.add(type);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 28),

                  // ── Lokasi Penjual ──────────────────────────────────
                  _SheetSectionHeader(
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi Penjual',
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 12),
                  if (widget.availableLocations.isEmpty)
                    _EmptyChipHint(
                        text: 'Belum ada data lokasi', cs: cs, tt: tt)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availableLocations.map((city) {
                        final isSelected = _selectedLocations.contains(city);
                        return _SelectableChip(
                          label: city,
                          isSelected: isSelected,
                          prefixIcon: Icons.location_on_rounded,
                          selectedColor: cs.secondary,
                          selectedTextColor: cs.onSecondary,
                          cs: cs,
                          tt: tt,
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedLocations.remove(city);
                            } else {
                              _selectedLocations.add(city);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 28),

                  // ── Rentang Harga ───────────────────────────────────
                  _SheetSectionHeader(
                    icon: Icons.payments_outlined,
                    label: 'Rentang Harga',
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Flexible(
                        child: _PriceRangeBox(
                          label: 'Harga Min',
                          value: 'Rp ${_fmtPrice(_priceRange.start)}',
                          cs: cs,
                          tt: tt,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                      ),
                      Flexible(
                        child: _PriceRangeBox(
                          label: 'Harga Max',
                          value: _priceRange.end >= _effectiveMaxPrice
                              ? 'Tidak Terbatas'
                              : 'Rp ${_fmtPrice(_priceRange.end)}',
                          cs: cs,
                          tt: tt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: cs.primary,
                      inactiveTrackColor: cs.surfaceContainerHighest,
                      thumbColor: cs.primary,
                      overlayColor: cs.primary.withOpacity(0.12),
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 12),
                      trackHeight: 4,
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: _effectiveMaxPrice,
                      divisions: 100,
                      onChanged: (values) {
                        setState(() => _priceRange = values);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rp 0',
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      Text('Rp ${_fmtPrice(_effectiveMaxPrice)}+',
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Penilaian Produk ────────────────────────────────
                  _SheetSectionHeader(
                    icon: Icons.star_outline_rounded,
                    label: 'Penilaian Minimum',
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // "Semua" option
                      _RatingChip(
                        label: 'Semua',
                        isSelected: _minRating == 0,
                        cs: cs,
                        tt: tt,
                        onTap: () => setState(() => _minRating = 0),
                      ),
                      ...List.generate(5, (i) {
                        final star = (i + 1).toDouble();
                        return _RatingChip(
                          label: '${star.toInt()}+',
                          stars: star.toInt(),
                          isSelected: _minRating == star,
                          cs: cs,
                          tt: tt,
                          onTap: () => setState(() => _minRating = star),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),

          // ── Apply button ────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Terapkan Filter',
                  style: tt.labelLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter sheet sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SheetSectionHeader extends StatelessWidget {
  const _SheetSectionHeader({
    required this.icon,
    required this.label,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.cs,
    required this.tt,
    required this.onTap,
    this.prefixIcon,
  });
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedTextColor;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? selectedColor : cs.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                size: 13,
                color:
                    isSelected ? selectedTextColor : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: isSelected ? selectedTextColor : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_rounded,
                  size: 13, color: selectedTextColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.isSelected,
    required this.cs,
    required this.tt,
    required this.onTap,
    this.stars,
  });
  final String label;
  final bool isSelected;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;
  final int? stars;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFC107);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (stars != null ? gold : cs.primary)
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? (stars != null ? gold : cs.primary)
                : cs.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stars != null) ...[
              Icon(
                Icons.star_rounded,
                size: 14,
                color: isSelected ? Colors.white : gold,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: isSelected ? Colors.white : cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRangeBox extends StatelessWidget {
  const _PriceRangeBox({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(
            value,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyChipHint extends StatelessWidget {
  const _EmptyChipHint(
      {required this.text, required this.cs, required this.tt});
  final String text;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style:
              tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0D3B6E), Color(0xFF1565C0)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Eco icon decoration
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.eco_rounded,
                size: 130,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PREMIUM COMMODITY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Trade the Future\nof Carbon.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Browse Origin',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Grid — uses filteredListingsProvider
// ─────────────────────────────────────────────────────────────────────────────
class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredListingsProvider);
    final filter = ref.watch(productFilterProvider);
    final query = ref.watch(searchQueryProvider);

    return filteredAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _EmptyState(
          icon: Icons.error_outline_rounded,
          message: 'Terjadi kesalahan.\nSilakan coba lagi.',
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          final hasFilter = filter.isActive || query.isNotEmpty;
          return SliverToBoxAdapter(
            child: _EmptyState(
              icon: hasFilter
                  ? Icons.search_off_rounded
                  : Icons.storefront_outlined,
              message: hasFilter
                  ? 'Tidak ada produk yang sesuai\ndengan filter yang dipilih.'
                  : 'Belum ada produk tersedia.\nTunggu seller mengunggah produk.',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ProductCard(listing: listings[index]),
              childCount: listings.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.7,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.listing});
  final ProductListing listing;

  String get _formattedPrice {
    final formatted = listing.price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Watch average rating for this product
    final ratingsMap = ref.watch(productAverageRatingsProvider).maybeWhen(
          data: (r) => r,
          orElse: () => <String, double>{},
        );
    final avgRating = ratingsMap[listing.id];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailScreen(product: listing.toProductModel()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: listing.imageUrl.isNotEmpty
                    ? Image.network(
                        listing.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _ImagePlaceholder();
                        },
                        errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                      )
                    : _ImagePlaceholder(),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _formattedPrice,
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${listing.unit}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating row (if available)
                  if (avgRating != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 12, color: const Color(0xFFFFC107)),
                        const SizedBox(width: 3),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (listing.badge.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 13, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            listing.badge,
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.45),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem(
        icon: Icons.storefront_outlined,
        active: Icons.storefront_rounded,
        label: 'MARKET'),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        active: Icons.receipt_long_rounded,
        label: 'ORDERS'),
    _NavItem(
        icon: Icons.shopping_cart_outlined,
        active: Icons.shopping_cart_rounded,
        label: 'CART'),
    _NavItem(
        icon: Icons.person_outline_rounded,
        active: Icons.person_rounded,
        label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final isSelected = i == selectedIndex;
          final item = _items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isSelected ? item.active : item.icon,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withOpacity(0.5),
                      size: 22,
                    ),
                  ),
                  if (!isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.label,
  });
  final IconData icon;
  final IconData active;
  final String label;
}