import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/buyer_dashboard/data/admin_order_repository.dart';
import '../../../../features/buyer_dashboard/data/order_model.dart';
import '../../../../features/courier_dashboard/data/courier_application_repository.dart';
import '../../../../features/courier_dashboard/domain/courier_application_providers.dart';
import '../../../../features/courier_dashboard/domain/models/courier_application_model.dart';
import '../../../../features/seller_registration/data/seller_application_repository.dart';
import '../../../../features/seller_registration/domain/models/seller_application_model.dart';
import '../../../../features/seller_registration/domain/seller_application_providers.dart';

// ── Main Widget (now ConsumerStatefulWidget) ─────────────────────────────────
class AdminVerifyScreen extends ConsumerStatefulWidget {
  const AdminVerifyScreen({super.key, this.tabNotifier});

  /// Optional notifier — set its value to jump to a specific tab from outside.
  final ValueNotifier<int>? tabNotifier;

  @override
  ConsumerState<AdminVerifyScreen> createState() => _AdminVerifyScreenState();
}

class _AdminVerifyScreenState extends ConsumerState<AdminVerifyScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab   = 0;
  int _sellerFilter  = 0; // 0=Pending, 1=Approved, 2=Rejected
  int _courierFilter = 0; // 0=Pending, 1=Approved, 2=Rejected
  int _paymentFilter = 0; // 0=Pending, 1=Verified, 2=Rejected
  int _refundFilter  = 0; // 0=Pending, 1=Approved, 2=Rejected
  String? _selectedOrderId; // order yang sedang ditampilkan detailnya

  final List<String> _tabs = [
    'Courier', 'Payment', 'Refund', 'Seller',
  ];
  final List<String> _sellerFilterLabels  = ['Pending', 'Approved', 'Rejected'];
  final List<String> _courierFilterLabels = ['Pending', 'Approved', 'Rejected'];
  final List<String> _paymentFilterLabels = ['Pending', 'Verified', 'Rejected'];
  final List<String> _paymentStatusKeys   = ['pending_verification', 'verified', 'rejected'];
  final List<String> _refundFilterLabels  = ['Pending', 'Approved', 'Rejected'];
  static const _statusKeys = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    widget.tabNotifier?.addListener(_onExternalTabChange);
  }

  void _onExternalTabChange() {
    if (mounted) setState(() => _selectedTab = widget.tabNotifier!.value);
  }

  @override
  void dispose() {
    widget.tabNotifier?.removeListener(_onExternalTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSellerTab  = _selectedTab == 3;
    final isCourierTab = _selectedTab == 0;
    final isPaymentTab = _selectedTab == 1;
    final isRefundTab  = _selectedTab == 2;

    // ── Seller stream ──
    final sellerAsync = ref.watch(allSellerApplicationsProvider(null));
    final allSellerApps  = sellerAsync.value ?? [];
    final sellerCounts = [
      allSellerApps.where((a) => a.isPending).length,
      allSellerApps.where((a) => a.isApproved).length,
      allSellerApps.where((a) => a.isRejected).length,
    ];
    final filteredSellerApps = allSellerApps
        .where((a) => a.status == _statusKeys[_sellerFilter])
        .toList();
    final isSellerLoading = sellerAsync.isLoading && allSellerApps.isEmpty;

    // ── Courier stream ──
    final courierAsync = ref.watch(allCourierApplicationsProvider(null));
    final allCourierApps = courierAsync.value ?? [];
    final courierCounts = [
      allCourierApps.where((a) => a.isPending).length,
      allCourierApps.where((a) => a.isApproved).length,
      allCourierApps.where((a) => a.isRejected).length,
    ];
    final filteredCourierApps = allCourierApps
        .where((a) => a.status == _statusKeys[_courierFilter])
        .toList();
    final isCourierLoading = courierAsync.isLoading && allCourierApps.isEmpty;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: cs.surfaceContainerLowest,
            floating: true,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sync_rounded, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text('EcoTrade',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: cs.onSurface)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.error, borderRadius: BorderRadius.circular(6)),
                  child: Text('ADMIN',
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onError, fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main tabs ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final sel = _selectedTab == i;
                        // Badge pada tab Seller (index 3) dan Courier (index 0) jika ada pending
                        final isPendingBadge = (i == 3 && sellerCounts[0] > 0) ||
                                              (i == 0 && courierCounts[0] > 0);
                        final badgeCount = i == 3 ? sellerCounts[0] : courierCounts[0];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTab = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel ? cs.primary : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_tabs[i],
                                    style: textTheme.labelMedium?.copyWith(
                                      color: sel
                                          ? cs.onPrimary
                                          : cs.onSurface.withValues(alpha: 0.65),
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    )),
                                if (isPendingBadge) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 18, height: 18,
                                    decoration: BoxDecoration(
                                      color: cs.error,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$badgeCount',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800),
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

                  const SizedBox(height: 24),
                  Text(
                    isSellerTab
                        ? 'SELLER MANAGEMENT'
                        : isCourierTab
                            ? 'COURIER MANAGEMENT'
                            : isPaymentTab
                                ? 'PAYMENT MANAGEMENT'
                                : isRefundTab
                                    ? 'REFUND MANAGEMENT'
                                    : 'VERIFICATION',
                    style: textTheme.labelSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w800,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSellerTab
                        ? 'Seller Account Verification'
                        : isCourierTab
                            ? 'Courier Account Verification'
                            : isPaymentTab
                                ? 'Payment Verification'
                                : isRefundTab
                                    ? 'Refund Claims'
                                    : 'Pending Approvals',
                    style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSellerTab
                        ? 'Review and verify new seller account registrations before they go live.'
                        : isCourierTab
                            ? 'Review and verify new courier account registrations before they go live.'
                            : isPaymentTab
                                ? 'Review and process incoming payment transactions.'
                                : isRefundTab
                                    ? 'Review and manage refund requests from buyers.'
                                    : 'Review and manage pending verifications.',
                    style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55), height: 1.5),
                  ),

                  if (isSellerTab) ...[
                    const SizedBox(height: 20),
                    _buildSellerFilterBar(cs, textTheme, sellerCounts),
                  ],
                  if (isCourierTab) ...[
                    const SizedBox(height: 20),
                    _buildCourierFilterBar(cs, textTheme, courierCounts),
                  ],
                  if (isPaymentTab) ...[
                    const SizedBox(height: 20),
                    _buildPaymentFilterBar(cs, textTheme),
                  ],
                  if (isRefundTab) ...[
                    const SizedBox(height: 20),
                    _buildRefundFilterBar(cs, textTheme),
                  ],

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: isSellerTab
                ? _buildSellerContent(context, isSellerLoading, filteredSellerApps)
                : isCourierTab
                    ? _buildCourierContent(context, isCourierLoading, filteredCourierApps)
                    : isPaymentTab
                        ? _buildPaymentContent(context)
                        : isRefundTab
                            ? _buildRefundContent(context)
                            : SliverToBoxAdapter(child: _buildEmptyState(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerFilterBar(
      ColorScheme cs, TextTheme tt, List<int> counts) {
    final filterColors = [cs.primary, const Color(0xFF2E7D32), cs.error];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_sellerFilterLabels.length, (i) {
          final sel = _sellerFilter == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sellerFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? filterColors[i] : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: sel
                      ? [BoxShadow(
                          color: filterColors[i].withValues(alpha: 0.25),
                          blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${counts[i]}',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: sel
                              ? Colors.white
                              : cs.onSurface.withValues(alpha: 0.6),
                        )),
                    const SizedBox(height: 2),
                    Text(_sellerFilterLabels[i],
                        style: tt.labelSmall?.copyWith(
                          color: sel
                              ? Colors.white.withValues(alpha: 0.85)
                              : cs.onSurface.withValues(alpha: 0.5),
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSellerContent(
      BuildContext context,
      bool isLoading,
      List<SellerApplicationModel> apps) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (apps.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(context));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _SellerCard(
            key: ValueKey(apps[i].uid), // stable key agar tidak rebuild paksa
            app: apps[i],
            onApprove: apps[i].isPending ? () => _handleApprove(apps[i]) : null,
            onReject:  apps[i].isPending ? () => _handleReject(apps[i])  : null,
          ),
        ),
        childCount: apps.length,
      ),
    );
  }

  Future<void> _handleApprove(SellerApplicationModel app) async {
    final repo = ref.read(sellerApplicationRepositoryProvider);
    try {
      await repo.approveApplication(app.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${app.businessName} disetujui'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleReject(SellerApplicationModel app) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Jelaskan alasan penolakan...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tolak')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final repo = ref.read(sellerApplicationRepositoryProvider);
    try {
      await repo.rejectApplication(app.uid, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${app.businessName} ditolak'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ── COURIER methods ──────────────────────────────────────────────────────

  Widget _buildCourierFilterBar(
      ColorScheme cs, TextTheme tt, List<int> counts) {
    final filterColors = [cs.primary, const Color(0xFF2E7D32), cs.error];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_courierFilterLabels.length, (i) {
          final sel = _courierFilter == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _courierFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? filterColors[i] : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: sel
                      ? [BoxShadow(
                          color: filterColors[i].withValues(alpha: 0.25),
                          blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${counts[i]}',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: sel
                              ? Colors.white
                              : cs.onSurface.withValues(alpha: 0.6),
                        )),
                    const SizedBox(height: 2),
                    Text(_courierFilterLabels[i],
                        style: tt.labelSmall?.copyWith(
                          color: sel
                              ? Colors.white.withValues(alpha: 0.85)
                              : cs.onSurface.withValues(alpha: 0.5),
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCourierContent(
      BuildContext context,
      bool isLoading,
      List<CourierApplicationModel> apps) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (apps.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(context));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CourierCard(
            key: ValueKey(apps[i].uid),
            app: apps[i],
            onApprove: apps[i].isPending ? () => _handleCourierApprove(apps[i]) : null,
            onReject:  apps[i].isPending ? () => _handleCourierReject(apps[i])  : null,
          ),
        ),
        childCount: apps.length,
      ),
    );
  }

  Future<void> _handleCourierApprove(CourierApplicationModel app) async {
    final repo = ref.read(courierApplicationRepositoryProvider);
    try {
      await repo.approveApplication(app.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${app.fullName} disetujui sebagai kurir'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleCourierReject(CourierApplicationModel app) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Jelaskan alasan penolakan...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tolak')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final repo = ref.read(courierApplicationRepositoryProvider);
    try {
      await repo.rejectApplication(app.uid, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${app.fullName} ditolak'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ── PAYMENT methods ──────────────────────────────────────────────────────

  Widget _buildPaymentFilterBar(ColorScheme cs, TextTheme tt) {
    final filterColors = [cs.primary, const Color(0xFF2E7D32), cs.error];

    // Ambil count real dari tiap status stream
    final pendingAsync   = ref.watch(allOrdersStreamProvider(status: 'pending_verification'));
    final verifiedAsync  = ref.watch(verifiedGroupOrdersStreamProvider);
    final rejectedAsync  = ref.watch(allOrdersStreamProvider(status: 'rejected'));
    final counts = [
      pendingAsync.value?.length  ?? 0,
      verifiedAsync.value?.length ?? 0,
      rejectedAsync.value?.length ?? 0,
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_paymentFilterLabels.length, (i) {
          final sel = _paymentFilter == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _paymentFilter = i;
                _selectedOrderId = null; // reset pilihan detail saat ganti tab
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? filterColors[i] : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: sel
                      ? [BoxShadow(
                          color: filterColors[i].withValues(alpha: 0.25),
                          blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${counts[i]}',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : cs.onSurface.withValues(alpha: 0.6),
                        )),
                    const SizedBox(height: 2),
                    Text(_paymentFilterLabels[i],
                        style: tt.labelSmall?.copyWith(
                          color: sel
                              ? Colors.white.withValues(alpha: 0.85)
                              : cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaymentContent(BuildContext context) {
    // Tab Verified (index 1): gunakan dedicated provider tanpa List param
    final ordersAsync = _paymentFilter == 1
        ? ref.watch(verifiedGroupOrdersStreamProvider)
        : ref.watch(allOrdersStreamProvider(
            status: _paymentStatusKeys[_paymentFilter]));

    return ordersAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $e')),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildGenericEmptyState(
              context,
              icon: Icons.payments_outlined,
              iconColor: Theme.of(context).colorScheme.tertiary,
              title: 'Tidak ada Payment ${_paymentFilterLabels[_paymentFilter]}',
              subtitle: 'Transaksi payment dengan status "${_paymentFilterLabels[_paymentFilter]}"\nakan muncul di sini.',
            ),
          );
        }

        // Auto-select order pertama jika belum ada pilihan
        final selectedId = _selectedOrderId ?? orders.first.id;
        final selectedOrder = orders.firstWhere(
          (o) => o.id == selectedId,
          orElse: () => orders.first,
        );

        // Tampilkan maks 3 pending cards + "View more"
        const maxVisible = 3;
        final visibleOrders = orders.take(maxVisible).toList();
        final remaining    = orders.length - maxVisible;

        return SliverList(
          delegate: SliverChildListDelegate([
            // ── Header ──
            _PaymentHeader(count: orders.length, filterLabel: _paymentFilterLabels[_paymentFilter]),
            const SizedBox(height: 16),

            // ── Pending list ──
            ...visibleOrders.map((o) => _PaymentMiniCard(
              order: o,
              isSelected: o.id == selectedId,
              onTap: () => setState(() => _selectedOrderId = o.id),
            )),

            if (remaining > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: null, // ekspansi bisa dikembangkan nanti
                  child: Text(
                    'View $remaining more ${_paymentFilterLabels[_paymentFilter].toLowerCase()}',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Detail panel ──
            _PaymentDetailPanel(
              order: selectedOrder,
              isPending: _paymentFilter == 0,
              onConfirm: _paymentFilter == 0
                  ? () => _handlePaymentVerify(selectedOrder)
                  : null,
              onReject: _paymentFilter == 0
                  ? () => _handlePaymentReject(selectedOrder)
                  : null,
            ),

            const SizedBox(height: 32),
          ]),
        );
      },
    );
  }

  // ── Payment actions ─────────────────────────────────────────────────────────

  Future<void> _handlePaymentVerify(OrderModel order) async {
    final repo = ref.read(adminOrderRepositoryProvider);
    try {
      await repo.verifyPayment(order.id);
      if (mounted) {
        setState(() => _selectedOrderId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Pembayaran ${order.displayBuyerName} dikonfirmasi'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handlePaymentReject(OrderModel order) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Jelaskan alasan penolakan pembayaran...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final repo = ref.read(adminOrderRepositoryProvider);
    try {
      await repo.rejectPayment(order.id, reason);
      if (mounted) {
        setState(() => _selectedOrderId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Pembayaran ${order.displayBuyerName} ditolak'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ── REFUND methods ───────────────────────────────────────────────────────

  Widget _buildRefundFilterBar(ColorScheme cs, TextTheme tt) {
    final filterColors = [cs.primary, const Color(0xFF2E7D32), cs.error];
    final counts = [0, 0, 0]; // placeholder until data model exists
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_refundFilterLabels.length, (i) {
          final sel = _refundFilter == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _refundFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? filterColors[i] : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: sel
                      ? [BoxShadow(
                          color: filterColors[i].withValues(alpha: 0.25),
                          blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${counts[i]}',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : cs.onSurface.withValues(alpha: 0.6),
                        )),
                    const SizedBox(height: 2),
                    Text(_refundFilterLabels[i],
                        style: tt.labelSmall?.copyWith(
                          color: sel
                              ? Colors.white.withValues(alpha: 0.85)
                              : cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRefundContent(BuildContext context) {
    return SliverToBoxAdapter(
      child: _buildGenericEmptyState(
        context,
        icon: Icons.assignment_return_outlined,
        iconColor: Theme.of(context).colorScheme.error,
        title: 'Tidak ada Refund ${_refundFilterLabels[_refundFilter]}',
        subtitle: 'Klaim refund dengan status "${_refundFilterLabels[_refundFilter]}"\nakan muncul di sini.',
      ),
    );
  }

  // ── GENERIC EMPTY STATE ──────────────────────────────────────────────────

  Widget _buildGenericEmptyState(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: iconColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tabLabel = _selectedTab == 3
        ? _sellerFilterLabels[_sellerFilter]
        : _tabs[_selectedTab];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedTab == 3
                  ? Icons.person_add_outlined
                  : Icons.inbox_outlined,
              size: 36, color: cs.primary.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak ada ${_selectedTab == 3 ? "Seller" : "Data"} $tabLabel',
            style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            _selectedTab == 3
                ? 'Pendaftaran seller baru dengan status "$tabLabel"\nakan muncul di sini.'
                : 'Semua data sudah diproses.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5), height: 1.6)),
        ],
      ),
    );
  }
}

// ── Seller Card ───────────────────────────────────────────────────────────────
class _SellerCard extends StatefulWidget {
  final SellerApplicationModel app;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;

  const _SellerCard({
    super.key,
    required this.app,
    this.onApprove,
    this.onReject,
  });

  @override
  State<_SellerCard> createState() => _SellerCardState();
}

class _SellerCardState extends State<_SellerCard> {
  bool _isActing = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final app = widget.app;

    final (statusColor, statusLabel, statusIcon) = switch (app.status) {
      'approved' => (const Color(0xFF2E7D32), 'Approved', Icons.check_circle_rounded),
      'rejected' => (cs.error, 'Ditolak', Icons.cancel_rounded),
      _          => (cs.primary, 'Pending', Icons.hourglass_top_rounded),
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
                    style: tt.titleLarge?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name,
                          style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const SizedBox(height: 2),
                      Text(app.email,
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: tt.labelSmall?.copyWith(
                              color: statusColor, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 14),

            // Info chips
            Wrap(
              spacing: 12, runSpacing: 10,
              children: [
                _chip(context, Icons.storefront_rounded,   app.businessName),
                _chip(context, Icons.category_outlined,    app.commodityType),
                _chip(context, Icons.email_outlined,       app.email),
                _chip(context, Icons.schedule_rounded,
                    _formatDate(app.submittedAt)),
              ],
            ),

            // Business description
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Text('Deskripsi Bisnis',
                          style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(app.businessDescription,
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.75),
                          height: 1.6)),
                ],
              ),
            ),

            // ── Foto Produk (jika ada) ──
            if (app.commodityImageUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              _AdminImageSection(
                title: 'Foto Produk / Komoditi',
                imageUrl: app.commodityImageUrl,
              ),
            ],

            // Rejection reason (if rejected)
            if (app.isRejected && app.rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 15, color: cs.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alasan: ${app.rejectionReason}',
                        style: tt.bodySmall?.copyWith(
                            color: cs.error, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (pending only)
            if (app.isPending) ...[
              const SizedBox(height: 18),
              if (_isActing)
                // Loading state saat proses approve/reject
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isActing
                            ? null
                            : () async {
                                setState(() => _isActing = true);
                                try {
                                  await widget.onReject?.call();
                                } finally {
                                  if (mounted) setState(() => _isActing = false);
                                }
                              },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isActing
                            ? null
                            : () async {
                                setState(() => _isActing = true);
                                try {
                                  await widget.onApprove?.call();
                                } finally {
                                  if (mounted) setState(() => _isActing = false);
                                }
                              },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Setujui'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

  Widget _chip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Text(label,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Courier Card ──────────────────────────────────────────────────────────────
class _CourierCard extends StatefulWidget {
  final CourierApplicationModel app;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;

  const _CourierCard({
    super.key,
    required this.app,
    this.onApprove,
    this.onReject,
  });

  @override
  State<_CourierCard> createState() => _CourierCardState();
}

class _CourierCardState extends State<_CourierCard> {
  bool _isActing = false;

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final app = widget.app;

    final (statusColor, statusLabel, statusIcon) = switch (app.status) {
      'approved' => (const Color(0xFF2E7D32), 'Disetujui', Icons.check_circle_rounded),
      'rejected' => (cs.error, 'Ditolak', Icons.cancel_rounded),
      _          => (cs.primary, 'Pending', Icons.hourglass_top_rounded),
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: Icon(Icons.local_shipping_rounded,
                      color: const Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.fullName,
                          style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const SizedBox(height: 2),
                      Text(app.email,
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: tt.labelSmall?.copyWith(
                              color: statusColor, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 14),

            // Info chips
            Wrap(
              spacing: 12, runSpacing: 10,
              children: [
                _courierChip(context, Icons.location_on_outlined,    app.area),
                _courierChip(context, Icons.phone_outlined,          app.phone),
                _courierChip(context, Icons.email_outlined,          app.email),
                _courierChip(context, Icons.schedule_rounded,
                    _formatDate(app.submittedAt)),
              ],
            ),

            // ── Foto Identitas (KTP & SIM) ──
            if (app.ktpImageUrl.isNotEmpty || app.simImageUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (app.ktpImageUrl.isNotEmpty)
                _AdminImageSection(
                  title: 'Foto KTP',
                  imageUrl: app.ktpImageUrl,
                ),
              if (app.simImageUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                _AdminImageSection(
                  title: 'Foto SIM C',
                  imageUrl: app.simImageUrl,
                ),
              ],
            ] else ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFF856404)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dokumen identitas belum diunggah',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF856404),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Rejection reason (if rejected)
            if (app.isRejected && app.rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 15, color: cs.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alasan: ${app.rejectionReason}',
                        style: tt.bodySmall?.copyWith(
                            color: cs.error, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (pending only)
            if (app.isPending) ...[
              const SizedBox(height: 18),
              if (_isActing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isActing
                            ? null
                            : () async {
                                setState(() => _isActing = true);
                                try {
                                  await widget.onReject?.call();
                                } finally {
                                  if (mounted) setState(() => _isActing = false);
                                }
                              },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isActing
                            ? null
                            : () async {
                                setState(() => _isActing = true);
                                try {
                                  await widget.onApprove?.call();
                                } finally {
                                  if (mounted) setState(() => _isActing = false);
                                }
                              },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Setujui'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

  Widget _courierChip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF10B981).withValues(alpha: 0.8)),
        const SizedBox(width: 5),
        Text(label,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Reusable image preview section ───────────────────────────────────────────
class _AdminImageSection extends StatelessWidget {
  const _AdminImageSection({
    required this.title,
    required this.imageUrl,
    this.padding,
  });

  final String title;
  final String imageUrl;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final content = _buildContent(context, cs, tt);
    return padding != null ? Padding(padding: padding!, child: content) : content;
  }

  Widget _buildContent(BuildContext context, ColorScheme cs, TextTheme tt) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(Icons.image_outlined, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Image
        GestureDetector(
          onTap: () => _showFullImage(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: cs.surfaceContainerHigh,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (ctx, _, __) => Container(
                    width: double.infinity,
                    height: 200,
                    color: cs.surfaceContainerHigh,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            size: 40,
                            color: cs.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Gagal memuat gambar',
                            style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ),
                // Tap to zoom hint
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in_rounded,
                            size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Perbesar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Payment Header ─────────────────────────────────────────────────────────────
class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.count, required this.filterLabel});
  final int count;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPending = filterLabel == 'Pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPending
              ? [cs.primary, cs.primary.withValues(alpha: 0.8)]
              : [const Color(0xFF2E7D32), const Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? 'Waiting for Confirmation' : 'Payment $filterLabel',
                  style: tt.titleSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending
                      ? 'You have $count pending transaction${count == 1 ? '' : 's'} requiring manual bank transfer verification.'
                      : '$count transaction${count == 1 ? '' : 's'} with status "$filterLabel".',
                  style: tt.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Mini Card ──────────────────────────────────────────────────────────
class _PaymentMiniCard extends StatelessWidget {
  const _PaymentMiniCard({
    required this.order,
    required this.isSelected,
    required this.onTap,
  });
  final OrderModel order;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    final diff = now.difference(order.createdAt);
    String timeAgo;
    if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes} MINS AGO';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours} HOUR${diff.inHours > 1 ? 'S' : ''} AGO';
    } else {
      timeAgo = '${diff.inDays} DAY${diff.inDays > 1 ? 'S' : ''} AGO';
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer.withValues(alpha: 0.5) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primaryContainer,
              child: Text(
                order.displayBuyerName.isNotEmpty
                    ? order.displayBuyerName[0].toUpperCase()
                    : '?',
                style: tt.titleSmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.displayBuyerName,
                    style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: #${order.id.substring(0, 8).toUpperCase()}',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(order.total),
                  style: tt.titleSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Detail Panel ───────────────────────────────────────────────────────
class _PaymentDetailPanel extends StatefulWidget {
  const _PaymentDetailPanel({
    required this.order,
    required this.isPending,
    this.onConfirm,
    this.onReject,
  });
  final OrderModel  order;
  final bool        isPending;
  final Future<void> Function()? onConfirm;
  final Future<void> Function()? onReject;

  @override
  State<_PaymentDetailPanel> createState() => _PaymentDetailPanelState();
}

class _PaymentDetailPanelState extends State<_PaymentDetailPanel> {
  bool _acting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final order = widget.order;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy • HH:mm');

    final methodLabel = order.paymentMethod == 'bank_transfer'
        ? 'Manual Bank Transfer'
        : order.paymentMethod;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.05),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Payment Proof section ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Icon(Icons.image_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'PAYMENT PROOF',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (order.paymentProofUrl.isNotEmpty)
            _AdminImageSection(
              title: '',
              imageUrl: order.paymentProofUrl,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            )
          else
            Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              height: 140,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 32, color: cs.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 6),
                    Text('Bukti transfer tidak tersedia',
                        style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ),

          // ── Transaction Details ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Row(
              children: [
                Icon(Icons.receipt_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'TRANSACTION DETAILS',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nominal besar
                Text(
                  fmt.format(order.total),
                  style: tt.headlineSmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Invoice: ${order.batchCode}',
                  style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 14),
                _detailRow(context, 'Buyer', order.displayBuyerName),
                const SizedBox(height: 10),
                _detailRow(context, 'Payment Method', methodLabel),
                const SizedBox(height: 10),
                _detailRow(context, 'Bank Name', 'EcoTrust Bank'),
                const SizedBox(height: 10),
                _detailRow(context, 'Date Submitted',
                    dateFmt.format(order.createdAt.toLocal())),

                // ── Rincian item pesanan ──────────────────────────────────
                const SizedBox(height: 16),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 13, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'RINCIAN PESANAN',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...order.items.map((item) {
                  final itemFmt = NumberFormat.currency(
                      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama toko
                          Row(
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 13,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.sellerName,
                                  style: tt.labelSmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.55),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Nama produk
                          Text(
                            item.productTitle,
                            style: tt.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface),
                          ),
                          const SizedBox(height: 8),
                          // Harga satuan, qty, subtotal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${itemFmt.format(item.unitPrice)} × ${item.quantity} ${item.unit}',
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.6)),
                              ),
                              Text(
                                itemFmt.format(item.subtotal),
                                style: tt.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                if (order.rejectionReason != null && !widget.isPending) ...[
                  const SizedBox(height: 10),
                  _detailRow(context, 'Rejection Reason',
                      order.rejectionReason ?? '-',
                      valueColor: cs.error),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action buttons ─────────────────────────────────────────────────
          if (widget.isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _acting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : Column(
                      children: [
                        // Confirm
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              setState(() => _acting = true);
                              try { await widget.onConfirm?.call(); }
                              finally { if (mounted) setState(() => _acting = false); }
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Confirm Payment',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Reject
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              setState(() => _acting = true);
                              try { await widget.onReject?.call(); }
                              finally { if (mounted) setState(() => _acting = false); }
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Reject Payment',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.order.status == OrderStatus.verified
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                      : Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.order.status == OrderStatus.verified
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.order.status == OrderStatus.verified
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: widget.order.status == OrderStatus.verified
                          ? const Color(0xFF2E7D32)
                          : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.order.status == OrderStatus.verified
                          ? 'Pembayaran telah dikonfirmasi'
                          : 'Pembayaran ditolak',
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.order.status == OrderStatus.verified
                            ? const Color(0xFF2E7D32)
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
