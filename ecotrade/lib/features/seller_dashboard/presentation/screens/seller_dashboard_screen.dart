import 'package:flutter/material.dart';

// ============================================================
// seller_dashboard_screen.dart
// Layar dashboard untuk SELLER di aplikasi EcoTrade.
// Hanya menampilkan UI (frontend only, tanpa logika backend).
// Produk & order dikosongkan (belum tersedia), sesuai permintaan.
// ============================================================

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  // Indeks tab aktif pada bottom navigation bar
  int _selectedIndex = 0;

  // ── Warna utama sesuai spesifikasi desain ──
  static const Color primaryBlue = Color(0xFF005DA7);
  static const Color primaryGreen = Color(0xFFB9EEAB);
  static const Color greyText = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      // ── 1. APP BAR ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'EcoTrade',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
            // ── 2. BANNER SELAMAT DATANG ──
            _buildWelcomeBanner(),

            const SizedBox(height: 16),

            // ── 3. KARTU KATALOG "Produk yang Dijual" ──
            _buildKatalogCard(),

            const SizedBox(height: 16),

            // ── 4. KARTU TRANSAKSI "Orderan Masuk" ──
            _buildTransaksiCard(),

            const SizedBox(height: 16),
          ],
        ),
      ),

      // ── 5. BOTTOM NAVIGATION BAR ──
      bottomNavigationBar: _buildBottomNavBar(),
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              // Badge SELLER dengan indikator lingkaran hijau
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SELLER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Widget: Detail Button (digunakan di header kartu) ─────────────────────
  Widget _buildDetailButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'DETAIL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward,
            size: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ── Widget: Kartu Katalog "Produk yang Dijual" ────────────────────────────
  Widget _buildKatalogCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kartu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KATALOG',
                    style: TextStyle(
                      fontSize: 10,
                      color: greyText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Produk yang Dijual',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              _buildDetailButton(),
            ],
          ),

          const SizedBox(height: 16),

          // Isi kartu: kosong / belum tersedia
          // Perubahan: konten produk dikosongkan karena belum ada data produk
          _buildEmptyState('Produk belum tersedia'),
        ],
      ),
    );
  }

  // ── Widget: Kartu Transaksi "Orderan Masuk" ───────────────────────────────
  Widget _buildTransaksiCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Background hijau sangat muda sesuai spesifikasi
        color: const Color(0xFFE8F8E3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kartu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRANSAKSI',
                    style: TextStyle(
                      fontSize: 10,
                      color: greyText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Orderan Masuk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              _buildDetailButton(),
            ],
          ),

          const SizedBox(height: 16),

          // Isi kartu: kosong / belum tersedia
          // Perubahan: konten order dikosongkan karena belum ada data transaksi
          _buildEmptyState('Orderan belum tersedia'),
        ],
      ),
    );
  }

  // ── Widget: State kosong (belum tersedia) ─────────────────────────────────
  // Ditampilkan pada kartu yang belum memiliki data produk / order
  Widget _buildEmptyState(String message) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: greyText,
          ),
        ),
      ),
    );
  }

  // ── Widget: Bottom Navigation Bar ─────────────────────────────────────────
  Widget _buildBottomNavBar() {
    // Daftar menu navigasi — TIDAK ada menu admin
    final items = [
      {'icon': Icons.home_outlined, 'label': 'BERANDA'},
      {'icon': Icons.inventory_2_outlined, 'label': 'PRODUK'},
      {'icon': Icons.receipt_long_outlined, 'label': 'ORDER'},
      {'icon': Icons.person_outline, 'label': 'PROFIL'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isActive = index == _selectedIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  // Tab aktif: background hijau pill
                  color: isActive ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(
                      items[index]['icon'] as IconData,
                      size: 20,
                      color: isActive ? Colors.black87 : greyText,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 4),
                      Text(
                        items[index]['label'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}