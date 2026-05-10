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
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync     = ref.watch(myProductsProvider);
    final incomingAsync     = ref.watch(sellerIncomingOrdersProvider);
    final incomingOrders    = incomingAsync.value ?? [];
    final pendingCount      = incomingOrders
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
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
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
            const Text('DETAIL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                  Text('KATALOG',
                      style: TextStyle(fontSize: 10, color: greyText, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
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
    final rupiah = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRANSAKSI',
                            style: TextStyle(
                                fontSize: 10,
                                color: greyText,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
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
            if (newest == null)
              _buildEmptyState('Belum ada order masuk')
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            newest.firstItem?.productTitle ?? 'Produk',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: newest.status == OrderStatus.verified
                                ? const Color(0xFF1565C0)
                                : const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            newest.status == OrderStatus.verified
                                ? 'Baru'
                                : 'Diproses',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dari: ${newest.displayBuyerName}',
                          style: const TextStyle(
                              fontSize: 11, color: greyText),
                        ),
                        Text(
                          rupiah.format(newest.total),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue),
                        ),
                      ],
                    ),
                    if (incomingOrders.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${incomingOrders.length - 1} order lainnya',
                        style: const TextStyle(
                            fontSize: 11,
                            color: greyText,
                            fontStyle: FontStyle.italic),
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

  // ── Widget: Kartu Produk Terbaru (tampilan lengkap) ─────────────────────────
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
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(iconData, color: Colors.white, size: 28),
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
                Text(
                  product.commodityType,
                  style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Text(
                        'Stok ${product.stock} ${product.unit}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
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