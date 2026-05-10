import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  ('Pengiriman', OrderStatus.shipped),
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
      return all.where((o) =>
        o.status == OrderStatus.pendingVerification ||
        o.status == OrderStatus.verified ||
        o.status == OrderStatus.processing).toList();
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
    int rating = 5;
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24, left: 20, right: 20,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text('Beri Ulasan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  )),
              const SizedBox(height: 4),
              Text(
                order.firstItem?.productTitle ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              // Bintang rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSt(() => rating = i + 1),
                  child: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFFC107),
                    size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tulis ulasan Anda...',
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(orderRepositoryProvider).submitReview(
                      orderId: order.id,
                      rating: rating,
                      reviewText: ctrl.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Ulasan berhasil dikirim!'),
                          backgroundColor: cs.secondary,
                        ),
                      );
                    }
                  },
                  child: const Text('Kirim Ulasan',
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

  // ── Return Dialog ─────────────────────────────────────────────────────────
  void _showReturnDialog(OrderModel order, ColorScheme cs) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24, left: 20, right: 20,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text('Ajukan Pengembalian',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                )),
            const SizedBox(height: 4),
            Text(
              order.firstItem?.productTitle ?? '',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Jelaskan alasan pengembalian barang...',
                filled: true,
                fillColor: cs.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  Navigator.pop(context);
                  await ref.read(orderRepositoryProvider).requestReturn(
                    orderId: order.id,
                    reason: ctrl.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Permintaan pengembalian dikirim'),
                        backgroundColor: cs.error,
                      ),
                    );
                  }
                },
                child: const Text('Ajukan Pengembalian',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onReview,
    required this.onReturn,
  });

  final OrderModel  order;
  final VoidCallback onReview;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item       = order.firstItem;
    final isComplete  = order.status == OrderStatus.completed;
    final isShipped   = order.status == OrderStatus.shipped;
    final isRejected  = order.status == OrderStatus.rejected ||
                        order.status == OrderStatus.cancelled;
    final isPending   = order.status == OrderStatus.pendingVerification;
    final isProcessing = order.status == OrderStatus.processing ||
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
                  _MiniInfo(label: 'STATUS', value: 'In Delivery', cs: cs, alignRight: true),
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
            else if (isRejected)
              Text(
                order.status == OrderStatus.cancelled
                    ? 'CANCELLED BY SELLER'
                    : 'REJECTED BY SELLER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cs.error,
                  letterSpacing: 0.5,
                ),
              )
            else
              _ValueRow(
                label: 'TRANSACTION VALUE',
                value: rupiah.format(order.total),
                cs: cs,
              ),

            // ── Tombol aksi (hanya status Selesai) ─────────────────────────
            if (isComplete) ...[
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
      case OrderStatus.shipped:
        bg = cs.primaryContainer; fg = cs.onPrimaryContainer;
        label = 'IN\nDELIVERY'; break;
      case OrderStatus.processing:
      case OrderStatus.verified:
        bg = cs.tertiaryContainer; fg = cs.onTertiaryContainer;
        label = 'PROCESSING'; break;
      case OrderStatus.pendingVerification:
        bg = cs.surfaceContainerHigh; fg = cs.onSurfaceVariant;
        label = 'PENDING\nADMIN'; break;
      case OrderStatus.rejected:
        bg = cs.errorContainer; fg = cs.onErrorContainer;
        label = 'DITOLAK'; break;
      case OrderStatus.cancelled:
        bg = cs.errorContainer; fg = cs.onErrorContainer;
        label = 'DIBATALKAN'; break;
      default:
        bg = cs.surfaceContainerHigh; fg = cs.onSurfaceVariant;
        label = 'UNKNOWN';
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
