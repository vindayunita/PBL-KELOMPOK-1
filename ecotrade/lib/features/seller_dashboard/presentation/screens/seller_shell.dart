import 'package:flutter/material.dart';

import 'seller_dashboard_screen.dart';
import 'seller_produk_screen.dart';
import 'seller_order_screen.dart';
import 'seller_profil_screen.dart';

// ── Shell utama Seller Dashboard ──────────────────────────────────────────────
// Mengelola navigasi antar halaman seller melalui IndexedStack.
// Setiap tap pada navbar langsung mengganti tampilan tanpa reload.
class SellerShell extends StatefulWidget {
  const SellerShell({super.key, this.initialIndex = 0});

  /// Index awal halaman yang ditampilkan (0=Beranda, 1=Produk, 2=Order, 3=Profil)
  final int initialIndex;

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  late int _selectedIndex;
  late final List<Widget> _pages;

  static const Color primaryGreen = Color(0xFFB9EEAB);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      SellerDashboardScreen(onSelectTab: _setSelectedIndex), // index 0 — BERANDA
      const SellerProdukScreen(),                               // index 1 — PRODUK
      const SellerOrderScreen(),                                // index 2 — ORDER
      const SellerProfilScreen(),                               // index 3 — PROFIL
    ];
  }

  void _setSelectedIndex(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined,        active: Icons.home,        label: 'BERANDA'),
    _NavItem(icon: Icons.inventory_2_outlined,  active: Icons.inventory_2, label: 'PRODUK'),
    _NavItem(icon: Icons.receipt_long_outlined, active: Icons.receipt_long, label: 'ORDER'),
    _NavItem(icon: Icons.person_outline,        active: Icons.person,      label: 'PROFIL'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: semua screen tetap hidup, hanya visibilitas yang berubah
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
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
          children: List.generate(_navItems.length, (index) {
            final isActive = index == _selectedIndex;
            final item = _navItems[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.active : item.icon,
                      size: 22,
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
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

// ── Model item navbar ─────────────────────────────────────────────────────────
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
