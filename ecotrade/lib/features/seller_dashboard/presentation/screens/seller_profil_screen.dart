import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'seller_unggah_komoditi_screen.dart';

class SellerProfilScreen extends StatefulWidget {
  const SellerProfilScreen({super.key});

  @override
  State<SellerProfilScreen> createState() => _SellerProfilScreenState();
}

class _SellerProfilScreenState extends State<SellerProfilScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color primaryGreen  = Color(0xFFB9EEAB);
  static const Color darkGreen     = Color(0xFF3B6934);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF5F5F5);

  // Data diisi dari backend — kosong = tampil empty state
  final List<Map<String, dynamic>> _activities = [];
  int    _totalProduk     = 0;
  String _totalPendapatan = 'Rp 0';
  bool   _hasPendapatan   = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: const Text(
          'EcoTrade',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),
            const SizedBox(height: 20),
            _buildTotalProdukCard(),
            const SizedBox(height: 12),
            _buildTotalPendapatanCard(),
            const SizedBox(height: 24),
            _buildAktivitasTerkini(),
            const SizedBox(height: 24),
            _buildTambahProdukButton(),
            const SizedBox(height: 12),
            _buildKembaliButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildDashboardHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFIL TOKO',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: darkGreen, letterSpacing: 1.2),
        ),
        SizedBox(height: 4),
        Text(
          'Ringkasan Bisnis',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 2),
        Text(
          'CuanBarengUcok',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue),
        ),
      ],
    );
  }

  // ── Card Total Produk ───────────────────────────────────────────────────────
  Widget _buildTotalProdukCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Produk yang Dijual',
                    style: TextStyle(fontSize: 12, color: Color(0xFF414751))),
                const SizedBox(height: 8),
                Text(
                  '$_totalProduk',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFD4E3FF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_outlined, color: primaryBlue, size: 24),
          ),
        ],
      ),
    );
  }

  // ── Card Total Pendapatan ──────────────────────────────────────────────────
  Widget _buildTotalPendapatanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PENDAPATAN',
                  style: TextStyle(fontSize: 12, color: Color(0xFF414751), letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  _totalPendapatan,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF3F6D38)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _hasPendapatan ? () {} : null,
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF005DA7)),
                  label: const Text(
                    'CAIRKAN DANA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF005DA7)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFF005DA7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.payments_outlined, color: Color(0xFF3F6D38), size: 24),
          ),
        ],
      ),
    );
  }

  // ── Aktivitas Terkini ──────────────────────────────────────────────────────
  Widget _buildAktivitasTerkini() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 22,
              decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 10),
            const Text('Aktivitas Terkini',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 12),

        // Konten dinamis: list aktivitas atau empty state
        if (_activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Center(
              child: Text(
                'Belum ada aktivitas',
                style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w500),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: List.generate(_activities.length, (i) {
                final a = _activities[i];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(a['icon'] as IconData, size: 18, color: darkGreen),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a['title'] as String,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text(a['subtitle'] as String,
                                    style: const TextStyle(fontSize: 12, color: greyText)),
                              ],
                            ),
                          ),
                          Text(a['time'] as String,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: greyText)),
                        ],
                      ),
                    ),
                    if (i < _activities.length - 1)
                      const Divider(height: 1, indent: 66, endIndent: 16),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  // ── Tombol Tambah Produk ───────────────────────────────────────────────────
  Widget _buildTambahProdukButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SellerUnggahKomoditiScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text('Tambah Komoditi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Tombol Kembali ke Akun Buyer ───────────────────────────────────────────
  Widget _buildKembaliButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          // Kembali ke buyer dashboard
          // Gunakan go() agar GoRouter me-replace stack ke /dashboard
          context.go('/dashboard');
        },
        icon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF3B6934)),
        label: const Text(
          'Kembali ke Akun Buyer',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3B6934)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3B6934), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
