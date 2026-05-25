import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/order_model.dart';
import '../../data/order_repository.dart';

// ─── Riverpod stream provider ─────────────────────────────────────────────────
final _myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).myOrders();
});

// ─── Status filter tabs ───────────────────────────────────────────────────────
const _tabs = [
  ('Semua',      null),
  ('Diproses',   OrderStatus.processing),
  ('Pengiriman', OrderStatus.assigned),
  ('Retur',      OrderStatus.returnRequested),
  ('Selesai',    OrderStatus.completed),
  ('Ditolak',    OrderStatus.rejected),
];

class BuyerOrderScreen extends ConsumerStatefulWidget {
  const BuyerOrderScreen({super.key});

  @override
  ConsumerState<BuyerOrderScreen> createState() => _BuyerOrderScreenState();
}

class _BuyerOrderScreenState extends ConsumerState<BuyerOrderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<OrderModel> _filter(List<OrderModel> all) {
    final status = _tabs[_tab.index].$2;
    if (status == null) return all;
    if (status == OrderStatus.processing) {
      // Tab "Diproses": menunggu admin, sudah verified, atau sedang diproses seller
      return all.where((o) =>
        o.status == OrderStatus.pendingVerification ||
        o.status == OrderStatus.verified ||
        o.status == OrderStatus.processing).toList();
    }
    if (status == OrderStatus.assigned) {
      // Tab "Pengiriman": kurir sudah ditugaskan, dalam perjalanan, atau shipped
      return all.where((o) =>
        o.status == OrderStatus.assigned ||
        o.status == OrderStatus.pickedUp ||
        o.status == OrderStatus.shipped ||
        o.status == OrderStatus.delivered).toList();
    }
    if (status == OrderStatus.returnRequested) {
      // Tab "Retur": semua yang berkaitan dengan proses retur
      return all.where((o) =>
        o.status == OrderStatus.returnRequested ||
        o.status == OrderStatus.returnApproved ||
        o.status == OrderStatus.returnPickedUp ||
        o.status == OrderStatus.returnCompleted).toList();
    }
    return all.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(_myOrdersProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(cs),
            _buildTabBar(cs),
            Expanded(
              child: ordersAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: cs.primary),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: TextStyle(color: cs.error)),
                ),
                data: (all) {
                  final filtered = _filter(all);
                  if (filtered.isEmpty) return _buildEmpty(cs);
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _OrderCard(
                      order: filtered[i],
                      onReview: () => _showReviewDialog(filtered[i], cs),
                      onReturn: () => _showReturnDialog(filtered[i], cs),
                      onConfirm: () async {
                        await ref.read(orderRepositoryProvider).confirmOrderReceived(filtered[i].id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Pesanan dikonfirmasi selesai!'),
                              backgroundColor: cs.primary,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(ColorScheme cs) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE ORGANIC CURATOR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'My Orders',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Detailed history of your high-value organic\ncommodity exchanges.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.5),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  // ── Tab Bar ──────────────────────────────────────────────────────────────────
  Widget _buildTabBar(ColorScheme cs) => SizedBox(
    height: 40,
    child: TabBar(
      controller: _tab,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      indicator: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: cs.onPrimary,
      unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
    ),
  );

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmpty(ColorScheme cs) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            size: 34,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text('Belum ada pesanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            )),
        const SizedBox(height: 6),
        Text('Pesanan Anda akan muncul di sini',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.5),
            )),
      ],
    ),
  );

  // ── Review Dialog ─────────────────────────────────────────────────────────
  void _showReviewDialog(OrderModel order, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(order: order, cs: cs),
    );
  }

  // ── Return Dialog ─────────────────────────────────────────────────────────
  void _showReturnDialog(OrderModel order, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReturnRequestSheet(order: order, cs: cs),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onReview,
    required this.onReturn,
    required this.onConfirm,
  });

  final OrderModel  order;
  final VoidCallback onReview;
  final VoidCallback onReturn;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item              = order.firstItem;
    final isComplete        = order.status == OrderStatus.completed;
    final isDelivered       = order.status == OrderStatus.delivered;
    final isReturnRequested = order.status == OrderStatus.returnRequested;
    final isReturnApproved  = order.status == OrderStatus.returnApproved;
    final isReturnPickedUp  = order.status == OrderStatus.returnPickedUp;
    final isReturnCompleted = order.status == OrderStatus.returnCompleted;
    final isAnyReturn       = isReturnRequested || isReturnApproved || isReturnPickedUp || isReturnCompleted;
    final isShipped         = order.status == OrderStatus.shipped ||
                              order.status == OrderStatus.assigned ||
                              order.status == OrderStatus.pickedUp ||
                              order.status == OrderStatus.delivered;
    final isRejected        = order.status == OrderStatus.rejected ||
                              order.status == OrderStatus.cancelled;
    final isPending         = order.status == OrderStatus.pendingVerification;
    final isProcessing      = order.status == OrderStatus.processing ||
                              order.status == OrderStatus.verified;

    final rupiah = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: isRejected
            ? Border(left: BorderSide(color: cs.error, width: 4))
            : isAnyReturn
                ? Border(left: BorderSide(color: isReturnCompleted ? const Color(0xFF16A34A) : const Color(0xFFE65100), width: 4))
                : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris: gambar + judul + badge ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(imageUrl: item?.productImageUrl ?? ''),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.productTitle ?? 'Produk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch #${order.batchCode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),

            // ── Info kontekstual per status ─────────────────────────────────
            if (isComplete)
              _ValueRow(
                label: 'TRANSACTION VALUE',
                value: rupiah.format(order.total),
                cs: cs,
              )
            else if (isShipped)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniInfo(label: 'DEPARTED HUB', value: _fmt(order.createdAt), cs: cs),
                  _MiniInfo(
                    label: 'STATUS', 
                    value: isDelivered ? 'Tiba di Tujuan' : 'In Delivery', 
                    cs: cs, 
                    alignRight: true),
                ],
              )
            else if (isProcessing)
              Row(
                children: [
                  _ValueRow(
                    label: 'TRANSACTION VALUE',
                    value: rupiah.format(order.total),
                    cs: cs,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Quality check in progress...',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              )
            else if (isPending)
              Text(
                'Orders are typically verified within 2-4 business hours.',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (isReturnRequested)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner status retur
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.autorenew_rounded, size: 12, color: Color(0xFFE65100)),
                        const SizedBox(width: 5),
                        const Text(
                          'PERMINTAAN RETUR DIKIRIM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Info menunggu proses
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE65100).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFBF360C)),
                            SizedBox(width: 5),
                            Text(
                              'MENUNGGU KONFIRMASI SELLER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFBF360C),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Permintaan retur Anda sedang ditinjau oleh seller. '
                          'Anda akan mendapatkan konfirmasi dalam 1–3 hari kerja.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFBF360C),
                            height: 1.4,
                          ),
                        ),
                        // Alasan retur (jika ada)
                        if (order.returnReason != null &&
                            order.returnReason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'ALASAN RETUR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFBF360C),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.returnReason!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D4037),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            else if (isReturnApproved)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF2E7D32)),
                        SizedBox(width: 5),
                        Text(
                          'RETUR DISETUJUI SELLER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
                    ),
                    child: const Text(
                      'Retur Anda telah disetujui. Kurir sedang dalam perjalanan untuk menjemput barang.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), height: 1.4),
                    ),
                  ),
                ],
              )
            else if (isReturnPickedUp)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_rounded, size: 12, color: Color(0xFF1565C0)),
                        SizedBox(width: 5),
                        Text(
                          'KURIR MENJEMPUT BARANG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1565C0),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.25)),
                    ),
                    child: const Text(
                      'Barang retur sudah diambil kurir dan sedang dalam perjalanan ke seller.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1565C0), height: 1.4),
                    ),
                  ),
                ],
              )
            else if (isReturnCompleted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: Color(0xFF16A34A)),
                        SizedBox(width: 5),
                        Text(
                          'RETUR SELESAI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                    ),
                    child: const Text(
                      'Proses retur telah selesai. Barang telah dikembalikan ke seller.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), height: 1.4),
                    ),
                  ),
                ],
              )
            else if (isRejected)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label utama
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block_rounded, size: 12, color: cs.onErrorContainer),
                        const SizedBox(width: 5),
                        Text(
                          order.status == OrderStatus.cancelled
                              ? 'DIBATALKAN'
                              : 'DITOLAK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: cs.onErrorContainer,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Alasan penolakan (jika ada)
                  if (order.rejectionReason != null &&
                      order.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALASAN PENOLAKAN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: cs.error.withValues(alpha: 0.7),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.rejectionReason!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              )
            else
              _ValueRow(
                label: 'TRANSACTION VALUE',
                value: rupiah.format(order.total),
                cs: cs,
              ),

            // ── Tombol aksi ─────────────────────────
            if (isDelivered) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReturn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.onSurface,
                        side: BorderSide(
                            color: cs.outline.withValues(alpha: 0.5),
                            width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Request Return',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Konfirmasi Diterima',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isComplete) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: order.reviewText == null ? onReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.onSurface,
                    foregroundColor: cs.surface,
                    disabledBackgroundColor:
                        cs.onSurface.withValues(alpha: 0.12),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    order.reviewText != null ? 'Reviewed ✓' : 'Add Review',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg; Color fg; String label;
    switch (status) {
      case OrderStatus.completed:
        bg = cs.secondaryContainer; fg = cs.onSecondaryContainer;
        label = 'COMPLETED'; break;
      case OrderStatus.delivered:
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32);
        label = 'TIBA DI\nTUJUAN'; break;
      case OrderStatus.shipped:
        bg = cs.primaryContainer; fg = cs.onPrimaryContainer;
        label = 'IN\nDELIVERY'; break;
      case OrderStatus.assigned:
        bg = const Color(0xFFFFF3E0); fg = const Color(0xFFE65100);
        label = 'KURIR\nDITUGAS'; break;
      case OrderStatus.pickedUp:
        bg = cs.primaryContainer; fg = cs.onPrimaryContainer;
        label = 'DALAM\nPERJALANAN'; break;
      case OrderStatus.processing:
      case OrderStatus.verified:
        bg = cs.tertiaryContainer; fg = cs.onTertiaryContainer;
        label = 'PROCESSING'; break;
      case OrderStatus.pendingVerification:
        bg = cs.surfaceContainerHigh; fg = cs.onSurfaceVariant;
        label = 'PENDING\nADMIN'; break;
      case OrderStatus.returnRequested:
        bg = const Color(0xFFFFF3E0); fg = const Color(0xFFBF360C);
        label = 'RETUR\nDIPROSES'; break;
      case OrderStatus.returnApproved:
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32);
        label = 'RETUR\nDISETUJUI'; break;
      case OrderStatus.returnPickedUp:
        bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1565C0);
        label = 'KURIR\nMENJEMPUT'; break;
      case OrderStatus.returnCompleted:
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF16A34A);
        label = 'RETUR\nSELESAI'; break;
      case OrderStatus.rejected:
        bg = cs.errorContainer; fg = cs.onErrorContainer;
        label = 'DITOLAK'; break;
      case OrderStatus.cancelled:
        bg = cs.errorContainer; fg = cs.onErrorContainer;
        label = 'DIBATALKAN'; break;
      case OrderStatus.unknown:
        bg = cs.surfaceContainerHigh; fg = cs.onSurfaceVariant;
        label = 'UNKNOWN'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          height: 1.3,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Value Row ────────────────────────────────────────────────────────────────
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.cs,
  });
  final String label;
  final String value;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.45),
            letterSpacing: 0.8,
          )),
      const SizedBox(height: 3),
      Text(value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: cs.primary,
          )),
    ],
  );
}

// ─── Mini Info ────────────────────────────────────────────────────────────────
class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
    required this.cs,
    this.alignRight = false,
  });
  final String label;
  final String value;
  final ColorScheme cs;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment:
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.45),
            letterSpacing: 0.8,
          )),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          )),
    ],
  );
}

// ─── Product Thumbnail ────────────────────────────────────────────────────────
class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 60, height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(cs),
            )
          : _placeholder(cs),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
    width: 60, height: 60,
    color: cs.surfaceContainerHigh,
    child: Icon(Icons.eco_rounded,
        color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 28),
  );
}

// ─── Return Request Sheet ──────────────────────────────────────────────────────
/// Bottom sheet lengkap untuk mengajukan permintaan retur:
/// - Deskripsi wajib diisi
/// - Upload foto kondisi produk (maks 3 foto)
/// - Preview thumbnail dengan tombol hapus
/// - Loading state selama upload & submit
// ─── Review Sheet ────────────────────────────────────────────────────────────
/// Bottom sheet lengkap untuk mengulas produk:
/// - Rating bintang 1-5
/// - Teks ulasan
/// - Upload foto (maks 5)
/// - Upload video (maks 1) ditampilkan sebagai thumbnail
class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.order, required this.cs});
  final OrderModel  order;
  final ColorScheme cs;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _ctrl   = TextEditingController();
  final _picker = ImagePicker();

  int  _rating  = 5;
  bool _loading = false;

  final _photos = <({Uint8List bytes, String ext})>[];
  ({Uint8List bytes, String ext, String name})? _video;

  static const _maxPhotos = 5;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    final ext   = xFile.name.split('.').last.toLowerCase();
    setState(() => _photos.add((bytes: bytes, ext: ext)));
  }

  Future<void> _pickVideo() async {
    if (_video != null) return;
    final xFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (xFile == null) return;
    // Validasi format video
    final ext = xFile.name.split('.').last.toLowerCase();
    const validFormats = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'flv', 'wmv', 'm4v'];
    if (!validFormats.contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Format video tidak didukung. Gunakan: mp4, mov, avi, mkv, webm, 3gp, flv, wmv, m4v'),
            backgroundColor: widget.cs.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    final bytes = await xFile.readAsBytes();
    setState(() => _video = (bytes: bytes, ext: ext, name: xFile.name));
  }

  void _removePhoto(int i) => setState(() => _photos.removeAt(i));
  void _removeVideo()      => setState(() => _video = null);

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(orderRepositoryProvider).submitReview(
        orderId:      widget.order.id,
        productId:    widget.order.firstItem?.productId ?? '',
        purchaseType: widget.order.firstItem?.purchaseType ?? 'standard',
        rating:       _rating,
        reviewText:   text,
        photos:       _photos,
        video:        _video != null
            ? (bytes: _video!.bytes, ext: _video!.ext)
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ulasan berhasil dikirim!'),
            backgroundColor: widget.cs.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ulasan: $e'),
            backgroundColor: widget.cs.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final canSubmit = _ctrl.text.trim().isNotEmpty && !_loading;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20, left: 20, right: 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (_, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.rate_review_rounded,
                        color: cs.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Beri Ulasan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            )),
                        Text(
                          widget.order.firstItem?.productTitle ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Rating bintang
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () {
                      setState(() => _rating = i + 1);
                      setSt(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFC107),
                        size: 40,
                      ),
                    ),
                  )),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                    _rating == 5 ? 'Sangat Puas'
                        : _rating == 4 ? 'Puas'
                        : _rating == 3 ? 'Cukup'
                        : _rating == 2 ? 'Kurang'
                        : 'Sangat Kurang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
              // Teks ulasan
              Text('Tulis Ulasan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                maxLines: 3,
                onChanged: (_) => setSt(() {}),
                decoration: InputDecoration(
                  hintText: 'Bagaimana kualitas produk ini?',
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              // Upload foto
              Row(children: [
                Text('Foto Produk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    )),
                const SizedBox(width: 6),
                 Text('(maks $_maxPhotos foto, opsional)',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    )),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._photos.asMap().entries.map((entry) {
                      final idx   = entry.key;
                      final photo = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(photo.bytes, fit: BoxFit.cover),
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(idx),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_photos.length < _maxPhotos)
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant, width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                  size: 26),
                              const SizedBox(height: 4),
                              Text('Tambah',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurface.withValues(alpha: 0.4),
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Upload video
              Row(children: [
                Text('Video Produk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    )),
                const SizedBox(width: 6),
                Text('(maks 1, opsional)',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    )),
              ]),
              const SizedBox(height: 10),
              if (_video == null)
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_rounded,
                            color: cs.onSurface.withValues(alpha: 0.5),
                            size: 22),
                        const SizedBox(width: 8),
                        Text('Pilih video dari galeri',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            )),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.video_file_rounded,
                          color: cs.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _video!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _removeVideo,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Tombol kirim
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit
                        ? cs.primary
                        : cs.surfaceContainerHigh,
                    foregroundColor: canSubmit
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: canSubmit ? () async {
                    setSt(() {});
                    await _submit();
                  } : null,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Kirim Ulasan',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Return Request Sheet ──────────────────────────────────────────────────────
/// Bottom sheet lengkap untuk mengajukan permintaan retur:
/// - Deskripsi wajib diisi
/// - Upload foto kondisi produk (maks 3 foto)
/// - Preview thumbnail dengan tombol hapus
/// - Loading state selama upload & submit
class _ReturnRequestSheet extends ConsumerStatefulWidget {

  const _ReturnRequestSheet({required this.order, required this.cs});
  final OrderModel   order;
  final ColorScheme  cs;

  @override
  ConsumerState<_ReturnRequestSheet> createState() => _ReturnRequestSheetState();
}

class _ReturnRequestSheetState extends ConsumerState<_ReturnRequestSheet> {
  final _ctrl    = TextEditingController();
  final _picker  = ImagePicker();

  // Setiap entry: bytes + extension
  final _photos  = <({Uint8List bytes, String ext, String preview})>[];
  bool  _loading = false;

  static const _maxPhotos = 3;
  static const _orange    = Color(0xFFE65100);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;

    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    final ext   = xFile.name.split('.').last.toLowerCase();

    setState(() {
      _photos.add((bytes: bytes, ext: ext, preview: xFile.path));
    });
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    final reason = _ctrl.text.trim();
    if (reason.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(orderRepositoryProvider).requestReturnWithPhotos(
        orderId: widget.order.id,
        reason:  reason,
        photos:  _photos.map((p) => (bytes: p.bytes, ext: p.ext)).toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Permintaan retur berhasil dikirim!'),
            backgroundColor: _orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: widget.cs.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs       = widget.cs;
    final canSubmit = _ctrl.text.trim().isNotEmpty && !_loading;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20, left: 20, right: 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_return_rounded,
                      color: _orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajukan Pengembalian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        widget.order.firstItem?.productTitle ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Deskripsi alasan ──
            Text(
              'Deskripsi Masalah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (_, setSt) => TextField(
                controller: _ctrl,
                maxLines: 3,
                onChanged: (_) => setSt(() {}),
                decoration: InputDecoration(
                  hintText: 'Jelaskan kondisi produk dan alasan pengembalian...',
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _orange, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Upload foto kondisi produk ──
            Row(
              children: [
                Text(
                  'Foto Kondisi Produk',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text('(maks $_maxPhotos foto, opsional)',
                    style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Grid foto: thumbnail + tombol tambah
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Thumbnail yang sudah dipilih
                  ..._photos.asMap().entries.map((entry) {
                    final i     = entry.key;
                    final photo = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _orange.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(photo.bytes, fit: BoxFit.cover),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(i),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Tombol tambah foto
                  if (_photos.length < _maxPhotos)
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: cs.onSurface.withValues(alpha: 0.4), size: 26),
                            const SizedBox(height: 4),
                            Text(
                              'Tambah',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Foto kondisi produk membantu seller memproses retur lebih cepat.',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.4),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // ── Tombol submit ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: StatefulBuilder(
                builder: (_, setSt) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit ? _orange : cs.surfaceContainerHigh,
                    foregroundColor: canSubmit ? Colors.white : cs.onSurface.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: canSubmit ? () async {
                    setSt(() {});
                    await _submit();
                  } : null,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Kirim Permintaan Retur',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
