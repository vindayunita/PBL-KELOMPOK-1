import 'package:flutter/material.dart';
import 'seller_unggah_komoditi_screen.dart';

class SellerProdukScreen extends StatefulWidget {
  const SellerProdukScreen({super.key});

  @override
  State<SellerProdukScreen> createState() => _SellerProdukScreenState();
}

class _SellerProdukScreenState extends State<SellerProdukScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color primaryGreen  = Color(0xFFB9EEAB);
  static const Color darkGreen     = Color(0xFF3B6934);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  // Data diisi dari backend — kosong = tampil empty state
  final List<Map<String, dynamic>> _products = [];

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: greyText, letterSpacing: 1.2),
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

          // ── Daftar Produk atau Empty State ──
          Expanded(
            child: _products.isEmpty
                ? _buildProductEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _products.length,
                    itemBuilder: (context, index) => _buildProductItem(_products[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Widget: Empty State Produk ─────────────────────────────────────────────
  Widget _buildProductEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(44),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFFCCCCCC)),
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

  // ── Widget: Item Produk ────────────────────────────────────────────────────
  Widget _buildProductItem(Map<String, dynamic> product) {
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: product['iconColor'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(product['icon'] as IconData, color: product['iconTint'] as Color, size: 26),
              ),
              const Spacer(),
              const Icon(Icons.edit_outlined, size: 18, color: greyText),
            ]),
            const SizedBox(height: 12),
            Text(
              product['name'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              product['desc'] as String,
              style: const TextStyle(fontSize: 12, color: greyText, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('HARGA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: greyText, letterSpacing: 0.8)),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: product['harga'] as String,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const TextSpan(text: ' /kg', style: TextStyle(fontSize: 11, color: greyText)),
                ]),
              ),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('STOK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: greyText, letterSpacing: 0.8)),
              Row(children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(product['stok'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(width: 4),
                const Text('Kg', style: TextStyle(fontSize: 10, color: greyText, letterSpacing: 0.5)),
              ]),
            ]),
          ],
        ),
      ),
    );
  }
}
