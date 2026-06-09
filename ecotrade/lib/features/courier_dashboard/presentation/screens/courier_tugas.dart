import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../features/orders/data/order_repository.dart';
import '../../../../features/orders/domain/order_model.dart';
import '../../../../features/orders/domain/order_providers.dart';
import '../../../../features/seller_dashboard/data/seller_order_repository.dart';
import '../../../../shared/widgets/notification_badge.dart';
import 'courier_retur.dart';
import 'courier_tolak.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Courier Tugas Screen  (Tugas Aktif | Retur)
// ─────────────────────────────────────────────────────────────────────────────
class CourierTugasScreen extends ConsumerStatefulWidget {
  const CourierTugasScreen({
    super.key,
    this.tabNotifier,
  });

  /// Opsional: ValueNotifier dari parent untuk mengontrol tab aktif.
  /// 0 = Tugas Aktif, 1 = Retur
  final ValueNotifier<int>? tabNotifier;

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
    // Dengarkan notifier dari parent
    widget.tabNotifier?.addListener(_onTabNotifier);
  }

  void _onTabNotifier() {
    final idx = widget.tabNotifier?.value ?? 0;
    if (_tabController.index != idx) {
      _tabController.animateTo(idx);
    }
  }

  @override
  void dispose() {
    widget.tabNotifier?.removeListener(_onTabNotifier);
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
                const NotificationBadge(),
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
                        ? [
                            BoxShadow(
                                color: cs.primary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
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
// Tab 0 — Tugas Aktif
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
      data: (allTasks) {
        // Tugas yang belum diambil — kurir memilih mana yang mau diproses
        final pendingPickup = allTasks.where((t) => t.isAssigned).toList();
        // Tugas yang sudah diambil dan sedang dalam perjalanan
        final inDelivery = allTasks.where((t) => t.isPickedUp).toList();
        final totalCount = pendingPickup.length + inDelivery.length;

        return SingleChildScrollView(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF22C55E).withOpacity(0.4))),
                    child: Text('$totalCount Tugas',
                        style: tt.labelSmall?.copyWith(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 10)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (totalCount == 0)
                _buildEmptyState(context)
              else ...[
                // ── Seksi: Menunggu Diambil ───────────────────────────────
                if (pendingPickup.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.inbox_rounded,
                    iconColor: const Color(0xFF4A90E2),
                    bgColor: const Color(0xFFEFF6FF),
                    label: 'MENUNGGU DIAMBIL',
                    count: pendingPickup.length,
                    countColor: const Color(0xFF4A90E2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF4A90E2).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14,
                            color: const Color(0xFF4A90E2).withOpacity(0.8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilih tugas pengantaran yang ingin kamu ambil terlebih dahulu.',
                            style: tt.bodySmall?.copyWith(
                                color: const Color(0xFF1E40AF), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...pendingPickup.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TaskCard(task: task, mode: _TaskMode.pending),
                      )),
                  const SizedBox(height: 8),
                ],

                // ── Seksi: Dalam Pengiriman ───────────────────────────────
                if (inDelivery.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFF0891B2),
                    bgColor: const Color(0xFFECFEFF),
                    label: 'DALAM PENGIRIMAN',
                    count: inDelivery.length,
                    countColor: const Color(0xFF0891B2),
                  ),
                  const SizedBox(height: 14),
                  ...inDelivery.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TaskCard(task: task, mode: _TaskMode.inDelivery),
                      )),
                ],
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
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
        Icon(Icons.inbox_outlined,
            size: 48, color: cs.onSurface.withOpacity(0.25)),
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
// Section Header Widget
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.count,
    required this.countColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final int count;
  final Color countColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration:
              BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: iconColor)),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: countColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Text('$count',
              style: tt.labelSmall?.copyWith(
                  color: countColor, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task mode enum
// ─────────────────────────────────────────────────────────────────────────────
enum _TaskMode { pending, inDelivery }

// ─────────────────────────────────────────────────────────────────────────────
// Task Card — satu order assignment
// ─────────────────────────────────────────────────────────────────────────────
class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.mode});
  final OrderModel task;
  final _TaskMode mode;

  static final _idr = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool get _isPending => mode == _TaskMode.pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final headerColor = _isPending
        ? const Color(0xFF4A90E2)
        : const Color(0xFF0891B2);
    final headerIcon = _isPending
        ? Icons.assignment_ind_rounded
        : Icons.local_shipping_rounded;

    return Container(
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: _isPending
              ? Border.all(
                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                  width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: cs.shadow.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 3))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Status bar ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: headerColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18))),
          child: Row(children: [
            Icon(headerIcon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(task.status.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('#${task.orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

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
              address: task.sellerAddress.isNotEmpty
                  ? task.sellerAddress
                  : task.sellerCity.isNotEmpty
                      ? task.sellerCity
                      : 'Alamat seller belum tersedia',
            ),

            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Column(
                  children: List.generate(
                      3,
                      (_) => Container(
                            width: 2,
                            height: 8,
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
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // ── Detail Barang ──────────────────────────────────────────
            _sectionLabel(context, 'DETAIL BARANG'),
            const SizedBox(height: 12),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.grass_rounded,
                    color: Color(0xFF388E3C), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(task.productName,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
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

            // ── Action Buttons ──────────────────────────────────────────
            if (_isPending) ...[
              // Tugas assigned — kurir memilih apakah ambil atau tolak
              _actionButton(
                context: context,
                label: 'Ambil Tugas Ini',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF4A90E2),
                onPressed: () => _confirmAndPickUp(context, ref),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => _tolakTugas(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('Tolak Tugas',
                        style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ),
            ] else ...[
              // Tugas picked up — konfirmasi selesai kirim
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
            color:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.42)));
  }

  Widget _routeStop(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String name,
    required String address,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 44,
        height: 44,
        decoration:
            BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: iconColor)),
        const SizedBox(height: 2),
        Text(name,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.55), height: 1.4)),
      ])),
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
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26))),
      ),
    );
  }

  /// Konfirmasi dialog lalu ambil tugas (assigned → picked_up)
  Future<void> _confirmAndPickUp(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ambil Tugas Ini?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kamu akan mengambil tugas pengiriman ini:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4A90E2).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📦 ${task.productName}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('🏪 Seller: ${task.sellerName}',
                      style: const TextStyle(fontSize: 13)),
                  Text('🏠 Buyer: ${task.buyerName}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
                'Pastikan kamu sudah siap menuju seller untuk mengambil barang.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Ambil Tugas'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(orderRepositoryProvider).markPickedUp(task.orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Tugas diambil! Segera menuju ke seller.'),
          backgroundColor: Color(0xFF4A90E2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _markDelivered(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Terkirim',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Konfirmasi bahwa barang sudah berhasil diterima oleh buyer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A)),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _tolakTugas(BuildContext context, WidgetRef ref) async {
    final reason = await showTolakTugasSheet(context);
    if (reason == null || reason.isEmpty) return;

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await ref
          .read(sellerOrderRepositoryProvider)
          .reAssignCourier(task.orderId, currentUid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tugas ditolak. Mencari kurir lain...'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
