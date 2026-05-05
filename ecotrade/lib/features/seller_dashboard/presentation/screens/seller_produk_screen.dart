import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/product_repository.dart';
import '../../domain/product_model.dart';
import 'seller_unggah_komoditi_screen.dart';

class SellerProdukScreen extends ConsumerWidget {
  const SellerProdukScreen({super.key});

  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color darkGreen     = Color(0xFF3B6934);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: appBackground,

      // ── APP BAR ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: const Text(
          'EcoTrade',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ],
      ),

      // ── BODY ──
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + Tombol Tambahkan Komoditi ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRODUK',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: greyText, letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Daftar Produk Aktif',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SellerUnggahKomoditiScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Tambahkan Komoditi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Daftar Produk atau State ──
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat produk.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              data: (products) {
                if (products.isEmpty) return _buildEmptyState();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: products.length,
                  itemBuilder: (context, index) =>
                      _ProductCard(product: products[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(44),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40, color: Color(0xFFCCCCCC),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Produk belum tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan komoditi pertama Anda untuk mulai berjualan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ProductModel product;

  static const Color darkGreen = Color(0xFF3B6934);
  static const Color greyText  = Color(0xFF888888);

  String get _formattedPrice {
    final formatted = product.price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border(bottom: BorderSide(color: darkGreen, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: image / icon + edit button
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Thumbnail or commodity icon
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        width: 52, height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _CommodityIcon(type: product.commodityType),
                      )
                    : _CommodityIcon(type: product.commodityType),
              ),
              const Spacer(),
              const Icon(Icons.edit_outlined, size: 18, color: greyText),
            ]),

            const SizedBox(height: 12),

            // ── Nama produk
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            // ── Badge / tipe komoditi
            if (product.commodityType.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.commodityType,
                  style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: darkGreen, letterSpacing: 0.5,
                  ),
                ),
              ),

            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                product.description,
                style: const TextStyle(fontSize: 12, color: greyText, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // ── Harga
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text(
                'HARGA',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: greyText, letterSpacing: 0.8,
                ),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: _formattedPrice,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: ' /${product.unit}',
                    style: const TextStyle(fontSize: 11, color: greyText),
                  ),
                ]),
              ),
            ]),

            const SizedBox(height: 6),

            // ── Stok
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text(
                'STOK',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: greyText, letterSpacing: 0.8,
                ),
              ),
              Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  '${product.stock}',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  product.unit,
                  style: const TextStyle(fontSize: 10, color: greyText, letterSpacing: 0.5),
                ),
              ]),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Commodity Icon (fallback when no image) ──────────────────────────────────
class _CommodityIcon extends StatelessWidget {
  const _CommodityIcon({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _resolveStyle(type);
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }

  (Color, IconData) _resolveStyle(String type) {
    final t = type.toLowerCase();
    if (t.contains('serat')) return (const Color(0xFF8B6914), Icons.grass_rounded);
    if (t.contains('biomassa') || t.contains('energi'))
      return (const Color(0xFF2E7D32), Icons.local_fire_department_rounded);
    if (t.contains('pupuk') || t.contains('pertanian'))
      return (const Color(0xFF558B2F), Icons.eco_rounded);
    if (t.contains('industri')) return (const Color(0xFF1565C0), Icons.factory_rounded);
    return (const Color(0xFF005DA7), Icons.inventory_2_rounded);
  }
}
