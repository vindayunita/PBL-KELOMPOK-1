import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../seller_dashboard/domain/product_model.dart';
import 'product_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: produk aktif milik seller tertentu (by sellerId)
// ─────────────────────────────────────────────────────────────────────────────
final _sellerProductsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, sellerId) async {
  final snap = await FirebaseFirestore.instance
      .collection('products')
      .where('sellerId', isEqualTo: sellerId)
      .where('status', isEqualTo: 'active')
      .get();
  final list = snap.docs.map(ProductModel.fromFirestore).toList();
  list.sort((a, b) => (b.createdAt ?? DateTime(2000))
      .compareTo(a.createdAt ?? DateTime(2000)));
  return list;
});

// ─────────────────────────────────────────────────────────────────────────────
// Provider: statistik rating toko
// ─────────────────────────────────────────────────────────────────────────────
final _buyerStoreReviewStatsProvider =
    FutureProvider.autoDispose.family<({double avg, int total}), String>(
        (ref, sellerId) async {
  final snap = await FirebaseFirestore.instance
      .collection('reviews')
      .where('sellerId', isEqualTo: sellerId)
      .get();
  if (snap.docs.isEmpty) return (avg: 0.0, total: 0);
  final ratings = snap.docs
      .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0.0)
      .toList();
  return (
    avg: ratings.fold(0.0, (a, b) => a + b) / ratings.length,
    total: snap.docs.length,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Provider: total produk terjual dari toko (completed orders)
// ─────────────────────────────────────────────────────────────────────────────
final _buyerStoreSoldProvider =
    FutureProvider.autoDispose.family<int, String>((ref, sellerId) async {
  final snap = await FirebaseFirestore.instance
      .collection('orders')
      .where('sellerId', isEqualTo: sellerId)
      .where('status', isEqualTo: 'completed')
      .get();
  int total = 0;
  for (final doc in snap.docs) {
    final items = doc.data()['items'] as List<dynamic>? ?? [];
    for (final item in items) {
      total += (item['quantity'] as num?)?.toInt() ?? 0;
    }
  }
  return total;
});

// ─────────────────────────────────────────────────────────────────────────────
// BuyerStoreViewScreen
// ─────────────────────────────────────────────────────────────────────────────
class BuyerStoreViewScreen extends ConsumerWidget {
  const BuyerStoreViewScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerCity,
  });

  final String sellerId;
  final String sellerName;
  final String sellerCity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_sellerProductsProvider(sellerId));
    final reviewAsync   = ref.watch(_buyerStoreReviewStatsProvider(sellerId));
    final soldAsync     = ref.watch(_buyerStoreSoldProvider(sellerId));

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Header toko ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF005DA7), Color(0xFF003F7A)],
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 20,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tombol back
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                // Ikon toko
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.store_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Nama toko
                      Text(
                        sellerName.isNotEmpty ? sellerName : 'EcoTrade Seller',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (sellerCity.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.white60, size: 12),
                          const SizedBox(width: 3),
                          Text(sellerCity,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ]),
                      ],
                      const SizedBox(height: 6),
                      // Rating & total terjual
                      Row(
                        children: [
                          // Rating
                          reviewAsync.when(
                            loading: () => const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white70),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (stats) => Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC107), size: 15),
                              const SizedBox(width: 3),
                              Text(
                                stats.avg > 0
                                    ? stats.avg.toStringAsFixed(1)
                                    : '0.0',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '(${stats.total} ulasan)',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 12),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 10),
                          Text('•',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4))),
                          const SizedBox(width: 10),
                          // Total terjual
                          const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          soldAsync.when(
                            loading: () => const SizedBox(
                                width: 10, height: 10,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white70)),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (sold) => Text(
                              '$sold terjual',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Grid produk 2 kolom ──────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Gagal memuat produk: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56,
                            color: cs.onSurface.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text('Belum ada produk',
                            style: tt.titleMedium?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.35))),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) =>
                      _BuyerProductCard(product: products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu produk di grid toko (buyer side)
// ─────────────────────────────────────────────────────────────────────────────
class _BuyerProductCard extends StatelessWidget {
  const _BuyerProductCard({required this.product});
  final ProductModel product;

  static const Color primaryBlue = Color(0xFF005DA7);
  static const Color darkGreen   = Color(0xFF3B6934);
  static const Color greyText    = Color(0xFF888888);

  String get _fmtPrice => product.price
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      )),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _IconFallback(type: product.commodityType))
                      : _IconFallback(type: product.commodityType),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.commodityType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: darkGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.commodityType.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: darkGreen),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('Rp $_fmtPrice',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue)),
                        const SizedBox(width: 2),
                        Text('/${product.unit}',
                            style: const TextStyle(
                                fontSize: 10, color: greyText)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: darkGreen, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Stok: ${product.stock} ${product.unit}',
                          style: const TextStyle(
                              fontSize: 10, color: greyText)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(type.toLowerCase());
    return Container(
        color: color,
        child: Center(child: Icon(icon, color: Colors.white, size: 40)));
  }

  (Color, IconData) _style(String t) {
    if (t.contains('serat'))
      return (const Color(0xFF8B6914), Icons.grass_rounded);
    if (t.contains('biomassa') || t.contains('energi'))
      return (const Color(0xFF2E7D32), Icons.local_fire_department_rounded);
    if (t.contains('pupuk') || t.contains('pertanian'))
      return (const Color(0xFF558B2F), Icons.eco_rounded);
    if (t.contains('industri'))
      return (const Color(0xFF1565C0), Icons.factory_rounded);
    return (const Color(0xFF005DA7), Icons.inventory_2_rounded);
  }
}
