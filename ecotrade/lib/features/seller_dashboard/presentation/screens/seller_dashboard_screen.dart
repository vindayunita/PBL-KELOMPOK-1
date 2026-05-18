import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/product_repository.dart';
import '../../data/seller_order_repository.dart';
import '../../domain/product_model.dart';
import '../../../buyer_dashboard/data/order_model.dart';
import 'seller_order_screen.dart';
import 'seller_produk_screen.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color primaryGreen  = Color(0xFFB9EEAB);
  static const Color darkGreen     = Color(0xFF3B6934);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync  = ref.watch(myProductsProvider);
    final incomingAsync  = ref.watch(sellerIncomingOrdersProvider);
    final incomingOrders = incomingAsync.value ?? [];
    final pendingCount   = incomingOrders
        .where((o) => o.status == OrderStatus.verified).length;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 16),
            _buildKatalogCard(context, productsAsync, onSelectTab),
            const SizedBox(height: 16),
            _buildTransaksiCard(context, onSelectTab, incomingOrders, pendingCount),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Widget: Banner ──────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBCF0AE),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SELLER',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Widget: Detail Button ───────────────────────────────────────────────────
  Widget _buildDetailButton({required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Teks DETAIL berwarna #3B6934
            const Text('DETAIL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkGreen)),
            const SizedBox(width: 4),
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, size: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget: Kartu Katalog ───────────────────────────────────────────────────
  Widget _buildKatalogCard(
    BuildContext context,
    AsyncValue<List<ProductModel>> productsAsync,
    ValueChanged<int>? onSelectTab,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label KATALOG → #3B6934
                  Text('KATALOG',
                      style: TextStyle(fontSize: 10, color: darkGreen, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                  SizedBox(height: 2),
                  Text('Produk yang Dijual',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              _buildDetailButton(
                onPressed: () {
                  if (onSelectTab != null) {
                    onSelectTab(1);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SellerProdukScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tampilkan 1 produk terbaru dari Firebase
          productsAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => _buildEmptyState('Gagal memuat produk'),
            data: (products) {
              if (products.isEmpty) return _buildEmptyState('Produk belum tersedia');
              return _buildLatestProductCard(products.first);
            },
          ),
        ],
      ),
    );
  }

  // ── Widget: Kartu Transaksi ─────────────────────────────────────────────────
  Widget _buildTransaksiCard(
    BuildContext context,
    ValueChanged<int>? onSelectTab,
    List<OrderModel> incomingOrders,
    int pendingCount,
  ) {
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final newest = incomingOrders.isNotEmpty ? incomingOrders.first : null;

    void goToOrders() {
      if (onSelectTab != null) {
        onSelectTab(2);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SellerOrderScreen()),
      );
    }

    return GestureDetector(
      onTap: goToOrders,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8E3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label TRANSAKSI → #3B6934
                        Text('TRANSAKSI',
                            style: TextStyle(
                                fontSize: 10,
                                color: darkGreen,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0)),
                        SizedBox(height: 2),
                        Text('Order Masuk',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pendingCount baru',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                _buildDetailButton(onPressed: goToOrders),
              ],
            ),
            const SizedBox(height: 16),

            // ── Order card ──
            if (newest == null)
              _buildEmptyState('Belum ada order masuk')
            else
              _buildNewestOrderCard(newest, rupiah, incomingOrders.length),
          ],
        ),
      ),
    );
  }

  // ── Widget: Card order terbaru (style sama dengan seller_order_screen) ───────
  Widget _buildNewestOrderCard(OrderModel order, NumberFormat fmt, int totalOrders) {
    final firstItem    = order.firstItem;
    final productName  = firstItem?.productTitle ?? 'Produk';
    final productImage = firstItem?.productImageUrl ?? '';
    final qty          = firstItem?.quantity ?? 0;
    final unit         = firstItem?.unit ?? 'kg';
    final purchaseType = firstItem?.purchaseType ?? '';
    final price        = fmt.format(order.total);

    final isVerified   = order.status == OrderStatus.verified;
    final isProcessing = order.status == OrderStatus.processing;
    final isAssigned   = order.status == OrderStatus.assigned;
    final isPickedUp   = order.status == OrderStatus.pickedUp;

    final badgeLabel = isVerified
        ? 'Baru'
        : isProcessing
            ? 'Dikemas'
            : isAssigned
                ? 'Kurir Ditugaskan'
                : isPickedUp
                    ? 'Dalam Perjalanan'
                    : order.status.label;
    final badgeBg = isVerified || isProcessing || isPickedUp
        ? const Color(0xFFDCEEFF)
        : isAssigned
            ? const Color(0x1A2976C7)
            : primaryGreen;
    final badgeText = isVerified || isProcessing || isPickedUp
        ? primaryBlue
        : isAssigned
            ? const Color(0xFF005DA7)
            : darkGreen;

    // Tipe pembelian
    final typeLabel = purchaseType.toLowerCase() == 'sample' ? 'Sample' : 'Standard';
    final typeBg    = purchaseType.toLowerCase() == 'sample'
        ? const Color(0x1A00581C) : const Color(0xFFE8F5E9);
    final typeColor = purchaseType.toLowerCase() == 'sample'
        ? const Color(0xFF00581C) : const Color(0xFF2E7D32);

    const labelStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: Color(0xFF717783), letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4F0CA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Row utama: Gambar (kiri) + semua info (kanan) ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Foto produk
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: productImage.isNotEmpty
                ? Image.network(productImage, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_outlined, color: Colors.grey, size: 26))
                : const Icon(Icons.image_outlined, color: Colors.grey, size: 26),
          ),
          const SizedBox(width: 12),

          // Kolom kanan: nama+badge, Standard/Sample, TOTAL PESANAN, TOTAL HARGA
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Nama produk + Badge status sejajar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: badgeText,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Tipe pembelian
              if (purchaseType.isNotEmpty) ...[
                if (purchaseType.toLowerCase() == 'sample')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(5)),
                    child: Text(typeLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor)),
                  )
                else
                  const Text(
                    'Standard',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF717783)),
                  ),
                const SizedBox(height: 8),
              ],

              // TOTAL PESANAN — label kiri, nilai kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL PESANAN', style: labelStyle),
                  Text('$qty $unit',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),

              // TOTAL HARGA — label kiri, nilai kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL HARGA', style: labelStyle),
                  Text(price,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue)),
                ],
              ),
            ]),
          ),
        ]),

        // Info order lainnya
        if (totalOrders > 1) ...[
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.green.shade200),
          const SizedBox(height: 6),
          Text(
            '+${totalOrders - 1} order lainnya — tap untuk lihat semua',
            style: const TextStyle(fontSize: 11, color: greyText, fontStyle: FontStyle.italic),
          ),
        ],
      ]),
    );
  }

  // ── Widget: Empty State ─────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 13, color: greyText)),
      ),
    );
  }

  // ── Widget: Kartu Produk Terbaru ────────────────────────────────────────────
  Widget _buildLatestProductCard(ProductModel product) {
    final (iconColor, iconData) = _resolveIcon(product.commodityType);
    final price = product.price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto produk
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    width: 56, height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(10)),
                      child: Icon(iconData, color: Colors.white, size: 28),
                    ),
                  )
                : Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(iconData, color: Colors.white, size: 28),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 3),
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
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 12, color: greyText, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Rp $price /${product.unit}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue),
                    ),
                    const Spacer(),
                    // Container stok: bg #E1E3E4, font #414751
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E3E4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Stok ${product.stock} ${product.unit}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414751)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _resolveIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('serat'))  return (const Color(0xFF8B6914), Icons.grass_rounded);
    if (t.contains('biomassa') || t.contains('energi'))
      return (const Color(0xFF2E7D32), Icons.local_fire_department_rounded);
    if (t.contains('pupuk') || t.contains('pertanian'))
      return (const Color(0xFF558B2F), Icons.eco_rounded);
    if (t.contains('industri')) return (const Color(0xFF1565C0), Icons.factory_rounded);
    return (const Color(0xFF005DA7), Icons.inventory_2_rounded);
  }
}
