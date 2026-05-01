import 'package:flutter/material.dart';

import 'seller_order_screen.dart';
import 'seller_produk_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color primaryGreen  = Color(0xFFB9EEAB);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  // Data diisi dari backend — kosong = tampil empty state
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _orders   = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,

      // ── APP BAR ──
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

      // ── BODY ──
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 16),
            _buildKatalogCard(),
            const SizedBox(height: 16),
            _buildTransaksiCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Widget: Banner Selamat Datang ──────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
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

  // ── Widget: Detail Button ──────────────────────────────────────────────────
  Widget _buildDetailButton({required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DETAIL',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
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

  // ── Widget: Kartu Katalog ──────────────────────────────────────────────────
  Widget _buildKatalogCard() {
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
                  if (widget.onSelectTab != null) {
                    widget.onSelectTab!(1);
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

          // Dinamis: tampilkan produk jika ada, atau empty state
          if (_products.isEmpty)
            _buildEmptyState('Produk belum tersedia')
          else
            Column(
              children: _products.map((p) => _buildProductRow(p)).toList(),
            ),
        ],
      ),
    );
  }

  // ── Widget: Kartu Transaksi ────────────────────────────────────────────────
  Widget _buildTransaksiCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8E3),
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
                  Text('TRANSAKSI',
                      style: TextStyle(fontSize: 10, color: greyText, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                  SizedBox(height: 2),
                  Text('Order Masuk',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              _buildDetailButton(
                onPressed: () {
                  if (widget.onSelectTab != null) {
                    widget.onSelectTab!(2);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SellerOrderScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dinamis: tampilkan order jika ada, atau empty state
          if (_orders.isEmpty)
            _buildEmptyState('Orderan belum tersedia')
          else
            Column(
              children: _orders.map((o) => _buildOrderRow(o)).toList(),
            ),
        ],
      ),
    );
  }

  // ── Widget: Empty State ────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 13, color: greyText)),
      ),
    );
  }

  // ── Widget: Baris Produk Ringkas ───────────────────────────────────────────
  Widget _buildProductRow(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: product['iconColor'] as Color? ?? const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(product['icon'] as IconData? ?? Icons.inventory_2_outlined,
                color: product['iconTint'] as Color? ?? Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(product['name'] as String? ?? '-',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Text(product['harga'] as String? ?? '-',
              style: const TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Widget: Baris Order Ringkas ────────────────────────────────────────────
  Widget _buildOrderRow(Map<String, dynamic> order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(order['productName'] as String? ?? '-',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Text(order['price'] as String? ?? '-',
              style: const TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}