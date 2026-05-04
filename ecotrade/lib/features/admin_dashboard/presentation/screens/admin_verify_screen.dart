import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/courier_dashboard/data/courier_application_repository.dart';
import '../../../../features/courier_dashboard/domain/courier_application_providers.dart';
import '../../../../features/courier_dashboard/domain/models/courier_application_model.dart';
import '../../../../features/seller_registration/data/seller_application_repository.dart';
import '../../../../features/seller_registration/domain/models/seller_application_model.dart';
import '../../../../features/seller_registration/domain/seller_application_providers.dart';

// ── Main Widget (now ConsumerStatefulWidget) ─────────────────────────────────
class AdminVerifyScreen extends ConsumerStatefulWidget {
  const AdminVerifyScreen({super.key});

  @override
  ConsumerState<AdminVerifyScreen> createState() => _AdminVerifyScreenState();
}

class _AdminVerifyScreenState extends ConsumerState<AdminVerifyScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab  = 0;
  int _sellerFilter = 0; // 0=Pending, 1=Approved, 2=Rejected
  int _courierFilter = 0; // 0=Pending, 1=Approved, 2=Rejected

  final List<String> _tabs = [
    'Product', 'Courier', 'Payment', 'Refund', 'Seller',
  ];
  final List<String> _sellerFilterLabels  = ['Pending', 'Approved', 'Rejected'];
  final List<String> _courierFilterLabels = ['Pending', 'Approved', 'Rejected'];
  static const _statusKeys = ['pending', 'approved', 'rejected'];

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSellerTab  = _selectedTab == 4;
    final isCourierTab = _selectedTab == 1;

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
                        // Badge pada tab Seller (index 4) dan Courier (index 1) jika ada pending
                        final isPendingBadge = (i == 4 && sellerCounts[0] > 0) ||
                                              (i == 1 && courierCounts[0] > 0);
                        final badgeCount = i == 4 ? sellerCounts[0] : courierCounts[0];
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
                            : 'MARKET INTEGRITY',
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
                            : 'Review incoming material batches for sustainability compliance.',
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

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tabLabel = _selectedTab == 4
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
              _selectedTab == 4
                  ? Icons.person_add_outlined
                  : Icons.inbox_outlined,
              size: 36, color: cs.primary.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak ada ${_selectedTab == 4 ? "Seller" : "Data"} $tabLabel',
            style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            _selectedTab == 4
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
