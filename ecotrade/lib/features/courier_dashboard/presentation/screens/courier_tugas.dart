import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/orders/data/order_repository.dart';
import '../../../../features/orders/domain/order_model.dart';
import '../../../../features/orders/domain/order_providers.dart';
import 'courier_retur.dart';
import 'courier_tolak.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Courier Tugas Screen  (Tugas Aktif | Retur) — now Firestore-connected
// ─────────────────────────────────────────────────────────────────────────────
class CourierTugasScreen extends ConsumerStatefulWidget {
  const CourierTugasScreen({super.key});

  @override
  ConsumerState<CourierTugasScreen> createState() => _CourierTugasScreenState();
}

class _CourierTugasScreenState extends ConsumerState<CourierTugasScreen>
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
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: cs.primaryContainer),
                  child: Icon(Icons.person_rounded, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Text('EcoTrade',
                    style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: 0.2)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
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
              children: const [
                _TugasAktifTab(),
                CourierReturBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Tab Bar
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
          borderRadius: BorderRadius.circular(24)),
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
                        ? [BoxShadow(
                            color: cs.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2))]
                        : []),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : cs.onSurface.withOpacity(0.5)),
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
// Tab 0 — Tugas Aktif (Firestore-connected)
// ─────────────────────────────────────────────────────────────────────────────
class _TugasAktifTab extends ConsumerWidget {
  const _TugasAktifTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myCourierTasksProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Header ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tugas Aktif',
                    style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: cs.onSurface)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.4))),
                  child: Text('${tasks.length} Tugas',
                      style: tt.labelSmall?.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontSize: 10)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (tasks.isEmpty)
              _buildEmptyState(context)
            else
              ...tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _TaskCard(task: task),
                  )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: cs.shadow.withOpacity(0.06), blurRadius: 12)
          ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 48,
            color: cs.onSurface.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('Belum ada tugas aktif',
            style: tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Tugas pengiriman dari seller akan muncul di sini\nsetelah kamu ditugaskan.',
          textAlign: TextAlign.center,
          style: tt.bodySmall
              ?.copyWith(color: cs.onSurface.withOpacity(0.45), height: 1.6),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Card — satu order assignment
// ─────────────────────────────────────────────────────────────────────────────
class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});
  final OrderModel task;

  static final _idr = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: cs.shadow.withOpacity(0.07), blurRadius: 14,
                offset: const Offset(0, 3))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Status bar ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: task.isPickedUp
                  ? const Color(0xFF0891B2)
                  : const Color(0xFF7C3AED),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18))),
          child: Row(children: [
            Icon(
              task.isPickedUp
                  ? Icons.local_shipping_rounded
                  : Icons.assignment_ind_rounded,
              color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(task.status.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('#${task.orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white60, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Rute Pengiriman ────────────────────────────────────────
            _sectionLabel(context, 'RUTE PENGIRIMAN'),
            const SizedBox(height: 12),

            _routeStop(
              context,
              label: 'AMBIL DARI SELLER',
              icon: Icons.store_rounded,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              name: task.sellerName,
              address: task.sellerCity.isNotEmpty
                  ? task.sellerCity
                  : 'Hubungi seller untuk alamat',
              actionIcon: Icons.call_rounded,
              actionColor: const Color(0xFF2E7D32),
              onAction: () {},
            ),

            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Column(children: List.generate(3, (_) => Container(
                width: 2, height: 8,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ))),
            ),

            _routeStop(
              context,
              label: 'ANTAR KE BUYER',
              icon: Icons.location_on_rounded,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              name: task.buyerName,
              address: task.buyerAddress.isNotEmpty
                  ? task.buyerAddress
                  : 'Alamat belum tersedia',
              actionIcon: Icons.call_rounded,
              actionColor: const Color(0xFF005DA7),
              onAction: () {},
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // ── Detail Barang ──────────────────────────────────────────
            _sectionLabel(context, 'DETAIL BARANG'),
            const SizedBox(height: 12),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.grass_rounded,
                    color: Color(0xFF388E3C), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.productName,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${task.quantity} ${task.unit}',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55))),
                const SizedBox(height: 4),
                Text(_idr.format(task.totalPrice),
                    style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005DA7))),
              ])),
            ]),

            const SizedBox(height: 20),

            // ── Action Button ──────────────────────────────────────────
            if (!task.isPickedUp) ...[
              _actionButton(
                context: context,
                label: 'Ambil Barang di Seller',
                icon: Icons.storefront_rounded,
                color: const Color(0xFF7C3AED),
                onPressed: () => _markPickedUp(context, ref),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => _tolakTugas(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('Tolak Tugas',
                        style: TextStyle(
                            color: cs.error, fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ),
            ] else ...[
              _actionButton(
                context: context,
                label: 'Konfirmasi Terkirim',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                onPressed: () => _markDelivered(context, ref),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.42)));
  }

  Widget _routeStop(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String name,
    required String address,
    required IconData actionIcon,
    required Color actionColor,
    required VoidCallback onAction,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800,
                letterSpacing: 0.8, color: iconColor)),
        const SizedBox(height: 2),
        Text(name,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(address,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.55), height: 1.4)),
      ])),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: onAction,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(actionIcon, color: actionColor, size: 18),
        ),
      ),
    ]);
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26))),
      ),
    );
  }

  Future<void> _markPickedUp(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Konfirmasi bahwa kamu sudah mengambil barang dari seller?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Sudah Ambil')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(orderRepositoryProvider).markPickedUp(task.orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Status diperbarui: Dalam Pengiriman'),
          backgroundColor: Color(0xFF0891B2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _markDelivered(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Terkirim', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Konfirmasi bahwa barang sudah berhasil diterima oleh buyer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Sudah Terkirim'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(orderRepositoryProvider).markDelivered(task.orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Pengiriman selesai!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _tolakTugas(BuildContext context) async {
    final reason = await showTolakTugasSheet(context);
    if (reason != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas ditolak: $reason'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
