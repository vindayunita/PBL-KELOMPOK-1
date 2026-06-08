import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/product_repository.dart';
import '../../domain/product_model.dart';
import 'seller_product_preview_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: statistik rating toko (rata-rata dari semua review produk)
// ─────────────────────────────────────────────────────────────────────────────
final sellerReviewStatsProvider =
    FutureProvider.autoDispose<({double avgRating, int totalReviews})>(
        (ref) async {
  final products = await ref.watch(myProductsProvider.future);
  if (products.isEmpty) return (avgRating: 0.0, totalReviews: 0);
  final allRatings = <double>[];
  for (final product in products) {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: product.id)
        .get();
    for (final r in snap.docs) {
      final rating = (r.data()['rating'] as num?)?.toDouble();
      if (rating != null) allRatings.add(rating);
    }
  }
  if (allRatings.isEmpty) return (avgRating: 0.0, totalReviews: 0);
  final avg = allRatings.fold(0.0, (a, b) => a + b) / allRatings.length;
  return (avgRating: avg, totalReviews: allRatings.length);
});

// ─────────────────────────────────────────────────────────────────────────────
// Provider: jumlah produk aktif di toko
// ─────────────────────────────────────────────────────────────────────────────
final sellerTotalSoldProvider = Provider.autoDispose<int>((ref) {
  final products = ref.watch(myProductsProvider).value ?? [];
  return products.where((p) => p.status == 'active').length;
});

// ─────────────────────────────────────────────────────────────────────────────
// SellerStoreViewScreen
// ─────────────────────────────────────────────────────────────────────────────
class SellerStoreViewScreen extends ConsumerWidget {
  const SellerStoreViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(myProductsProvider);
    final reviewStats   = ref.watch(sellerReviewStatsProvider);
    final totalSold     = ref.watch(sellerTotalSoldProvider);

    final sellerName = productsAsync.value?.isNotEmpty == true
        ? productsAsync.value!.first.sellerName
        : 'Toko Saya';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
              left: 16, right: 20,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Container(
                  width: 56, height: 56,
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
                      Text(sellerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Row(children: [
                        reviewStats.when(
                          loading: () => const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white70),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (stats) => Row(children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFC107), size: 15),
                            const SizedBox(width: 3),
                            Text(
                              stats.avgRating > 0
                                  ? stats.avgRating.toStringAsFixed(1)
                                  : '0.0',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 3),
                            Text('(${stats.totalReviews} ulasan)',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.65),
                                    fontSize: 12)),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        Text('•',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4))),
                        const SizedBox(width: 10),
                        const Icon(Icons.inventory_2_outlined,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text('$totalSold produk',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Grid produk ──────────────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Gagal memuat: $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54))),
              data: (products) {
                final active =
                    products.where((p) => p.status == 'active').toList();
                if (active.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 56, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 12),
                      Text('Belum ada produk aktif',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFAAAAAA))),
                    ]),
                  );
                }
                return LayoutBuilder(builder: (ctx, constraints) {
                  final w = (constraints.maxWidth - 16 - 16 - 12) / 2;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: active
                          .map((p) => SizedBox(
                                width: w,
                                child: _StoreProductCard(product: p),
                              ))
                          .toList(),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu produk di grid toko
// ─────────────────────────────────────────────────────────────────────────────
class _StoreProductCard extends StatelessWidget {
  const _StoreProductCard({required this.product});
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
        builder: (_) => SellerProductPreviewScreen(product: product),
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
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    Text(product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.3)),
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
