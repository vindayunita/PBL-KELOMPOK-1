import 'package:flutter/material.dart';

import 'courier_retur.dart';
import 'courier_tolak.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model tugas aktif (placeholder — swap dengan Firestore nantinya)
// ─────────────────────────────────────────────────────────────────────────────
class ActiveTask {
  const ActiveTask({
    required this.sellerName,
    required this.sellerAddress,
    required this.buyerName,
    required this.buyerAddress,
    required this.itemName,
    required this.itemDescription,
    required this.itemWeightKg,
    this.sellerPhotoUrl,
    this.buyerPhotoUrl,
    this.itemPhotoUrl,
  });

  final String sellerName;
  final String sellerAddress;
  final String buyerName;
  final String buyerAddress;
  final String itemName;
  final String itemDescription;
  final double itemWeightKg;
  final String? sellerPhotoUrl;
  final String? buyerPhotoUrl;
  final String? itemPhotoUrl;
}

// ─────────────────────────────────────────────────────────────────────────────
// Courier Tugas Screen  (Tugas Aktif | Retur)
// ─────────────────────────────────────────────────────────────────────────────
class CourierTugasScreen extends StatefulWidget {
  const CourierTugasScreen({super.key, this.activeTask});

  /// Pass null untuk tampilkan empty state
  final ActiveTask? activeTask;

  @override
  State<CourierTugasScreen> createState() => _CourierTugasScreenState();
}

class _CourierTugasScreenState extends State<CourierTugasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primaryContainer,
                  ),
                  child: Icon(Icons.person_rounded,
                      color: cs.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'EcoTrade',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: cs.onSurface),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ── Pill Tab Bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _PillTabBar(controller: _tabController),
          ),

          // ── Tab Views ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0 — Tugas Aktif
                _TugasAktifTab(activeTask: widget.activeTask),

                // Tab 1 — Retur
                const CourierReturBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Tab Bar  (Tugas Aktif | Retur)
// ─────────────────────────────────────────────────────────────────────────────
class _PillTabBar extends StatelessWidget {
  const _PillTabBar({required this.controller});

  final TabController controller;

  static const _labels = ['Tugas Aktif', 'Retur'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final selected = controller.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — Tugas Aktif content (scrollable)
// ─────────────────────────────────────────────────────────────────────────────
class _TugasAktifTab extends StatelessWidget {
  const _TugasAktifTab({this.activeTask});

  final ActiveTask? activeTask;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Header Row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Tugas Aktif',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              // EcoTrade Route badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  'EcoTrade Route',
                  style: tt.labelSmall?.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Rute Pengiriman Card ─────────────────────────────────────────
          _SectionCard(
            label: 'RUTE PENGIRIMAN',
            child: _EmptyCardContent(
              icon: Icons.route_rounded,
              message: 'Belum ada rute pengiriman',
            ),
          ),

          const SizedBox(height: 16),

          // ── Detail Barang Card ───────────────────────────────────────────
          _SectionCard(
            label: 'DETAIL BARANG',
            child: _EmptyCardContent(
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada detail barang',
            ),
          ),

          const SizedBox(height: 28),

          // ── Action Button ────────────────────────────────────────────────
          _ActionButton(
            onPressed: () {
              // TODO: implementasi ambil barang / update status
            },
          ),

          const SizedBox(height: 12),

          // ── Tolak Tugas ──────────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: () async {
                final reason = await showTolakTugasSheet(context);
                if (reason != null && context.mounted) {
                  // TODO: kirim alasan penolakan ke Firestore
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tugas ditolak: $reason'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tolak Tugas',
                  style: tt.labelLarge?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.42),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Route Stop Row (Seller / Buyer)  — kept for future use
// ─────────────────────────────────────────────────────────────────────────────
class _RouteStopRow extends StatelessWidget {
  const _RouteStopRow({
    required this.iconWidget,
    required this.label,
    required this.name,
    required this.address,
    required this.labelColor,
    required this.actionIcon,
    required this.actionColor,
    required this.onAction,
  });

  final Widget iconWidget;
  final String label;
  final String name;
  final String address;
  final Color labelColor;
  final IconData actionIcon;
  final Color actionColor;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.55),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAction,
          child: Icon(actionIcon, color: actionColor, size: 26),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Card Content placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(width: 10),
          Text(
            message,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button — "Ambil Barang di Seller"
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ambil Barang di Seller',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
