import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/payout_providers.dart';
import '../../data/payout_model.dart';
import '../../data/payout_repository.dart';

// ── Main Widget ───────────────────────────────────────────────────────────────
class AdminPayoutScreen extends ConsumerStatefulWidget {
  const AdminPayoutScreen({super.key, this.tabNotifier});

  /// Optional notifier — set its value to jump to a tab from outside.
  final ValueNotifier<int>? tabNotifier;

  @override
  ConsumerState<AdminPayoutScreen> createState() => _AdminPayoutScreenState();
}

class _AdminPayoutScreenState extends ConsumerState<AdminPayoutScreen> {
  // 0 = Payout Seller, 1 = Refund Processing
  int _selectedTab = 0;

  // Payout Seller filter: 0=Pending, 1=Processed, 2=Failed
  int _payoutFilter = 0;

  // Refund Processing filter: 0=Pending, 1=Approved, 2=Rejected
  int _refundFilter = 0;

  final List<String> _tabs = ['Payout Seller', 'Refund Processing'];

  final List<String> _payoutFilterLabels = ['Pending', 'Processed', 'Failed'];
  final List<String> _refundFilterLabels = ['Pending', 'Approved', 'Rejected'];

  // Placeholder counts (replace with real data when model is ready)
  final List<int> _payoutCounts = [0, 0, 0];
  final List<int> _refundCounts = [0, 0, 0];

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isPayoutTab = _selectedTab == 0;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: cs.surfaceContainerLowest,
            floating: true,
            elevation: 0,
            title: Text(
              'Admin Dashboard',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),

          // ── Header + Tabs + Filter ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary Banner ──
                  _SummaryBanner(cs: cs, tt: tt),

                  const SizedBox(height: 24),

                  // ── Tab Selector ──
                  _buildTabRow(cs, tt),

                  const SizedBox(height: 24),

                  // ── Section Label ──
                  Text(
                    isPayoutTab ? 'PAYOUT MANAGEMENT' : 'REFUND MANAGEMENT',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPayoutTab
                        ? 'Pencairan Dana Seller'
                        : 'Pengembalian Dana Buyer',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPayoutTab
                        ? 'Verifikasi dan proses pencairan dana hasil penjualan kepada seller.'
                        : 'Verifikasi dan proses pengembalian dana kepada buyer atas pesanan yang dikembalikan.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Filter Bar ──
                  if (isPayoutTab)
                    _buildFilterBar(
                      cs: cs,
                      tt: tt,
                      labels: _payoutFilterLabels,
                      counts: _payoutCounts,
                      selectedIndex: _payoutFilter,
                      onSelect: (i) => setState(() => _payoutFilter = i),
                      colors: [cs.primary, const Color(0xFF2E7D32), cs.error],
                    )
                  else
                    _buildFilterBar(
                      cs: cs,
                      tt: tt,
                      labels: _refundFilterLabels,
                      counts: _refundCounts,
                      selectedIndex: _refundFilter,
                      onSelect: (i) => setState(() => _refundFilter = i),
                      colors: [cs.primary, const Color(0xFF2E7D32), cs.error],
                    ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: isPayoutTab
                ? _buildPayoutContent(context, cs, tt)
                : _buildRefundContent(context, cs, tt),
          ),
        ],
      ),
    );
  }

  // ── Tab Row ──────────────────────────────────────────────────────────────────
  Widget _buildTabRow(ColorScheme cs, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final sel = _selectedTab == i;
          final tabColor = i == 0 ? cs.primary : cs.tertiary;
          final tabIcon =
              i == 0 ? Icons.account_balance_wallet_rounded : Icons.assignment_return_rounded;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: sel ? tabColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: tabColor.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabIcon,
                      size: 16,
                      color: sel
                          ? Colors.white
                          : cs.onSurface.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _tabs[i],
                        textAlign: TextAlign.center,
                        style: tt.labelMedium?.copyWith(
                          color: sel
                              ? Colors.white
                              : cs.onSurface.withValues(alpha: 0.65),
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Filter Bar ───────────────────────────────────────────────────────────────
  Widget _buildFilterBar({
    required ColorScheme cs,
    required TextTheme tt,
    required List<String> labels,
    required List<int> counts,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? colors[i] : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: colors[i].withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${counts[i]}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: sel
                            ? Colors.white
                            : cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[i],
                      style: tt.labelSmall?.copyWith(
                        color: sel
                            ? Colors.white.withValues(alpha: 0.85)
                            : cs.onSurface.withValues(alpha: 0.5),
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPayoutContent(BuildContext context, ColorScheme cs, TextTheme tt) {
    final asyncPayouts = ref.watch(payoutsByRoleProvider('seller'));

    return asyncPayouts.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Error: $e')),
        ),
      ),
      data: (payouts) {
        // Filter: 0=Pending, 1=Approved, 2=Rejected
        final filtered = payouts.where((p) {
          if (_payoutFilter == 0) return p.status == PayoutStatus.pending;
          if (_payoutFilter == 1) return p.status == PayoutStatus.approved;
          if (_payoutFilter == 2) return p.status == PayoutStatus.rejected;
          return false;
        }).toList();

        // Update counts (using microtask to avoid calling setState during build)
        Future.microtask(() {
          if (!mounted) return;
          final pendingCount = payouts.where((p) => p.status == PayoutStatus.pending).length;
          final approvedCount = payouts.where((p) => p.status == PayoutStatus.approved).length;
          final rejectedCount = payouts.where((p) => p.status == PayoutStatus.rejected).length;

          if (_payoutCounts[0] != pendingCount ||
              _payoutCounts[1] != approvedCount ||
              _payoutCounts[2] != rejectedCount) {
            setState(() {
              _payoutCounts[0] = pendingCount;
              _payoutCounts[1] = approvedCount;
              _payoutCounts[2] = rejectedCount;
            });
          }
        });

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyStateCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: cs.primary,
              title: 'Tidak ada Payout ${_payoutFilterLabels[_payoutFilter]}',
              subtitle: 'Permintaan pencairan dana seller dengan status\n"${_payoutFilterLabels[_payoutFilter]}" akan muncul di sini.',
              cs: cs,
              tt: tt,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final payout = filtered[index];
              return _PayoutRequestCard(payout: payout);
            },
            childCount: filtered.length,
          ),
        );
      },
    );
  }

  // ── Refund Content ────────────────────────────────────────────────────────────
  Widget _buildRefundContent(BuildContext context, ColorScheme cs, TextTheme tt) {
    final asyncPayouts = ref.watch(payoutsByRoleProvider('buyer'));

    return asyncPayouts.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Error: $e')),
        ),
      ),
      data: (payouts) {
        // Filter: 0=Pending, 1=Approved, 2=Rejected
        final filtered = payouts.where((p) {
          if (_refundFilter == 0) return p.status == PayoutStatus.pending;
          if (_refundFilter == 1) return p.status == PayoutStatus.approved;
          if (_refundFilter == 2) return p.status == PayoutStatus.rejected;
          return false;
        }).toList();

        // Update counts (using microtask to avoid calling setState during build)
        Future.microtask(() {
          if (!mounted) return;
          final pendingCount = payouts.where((p) => p.status == PayoutStatus.pending).length;
          final approvedCount = payouts.where((p) => p.status == PayoutStatus.approved).length;
          final rejectedCount = payouts.where((p) => p.status == PayoutStatus.rejected).length;

          if (_refundCounts[0] != pendingCount ||
              _refundCounts[1] != approvedCount ||
              _refundCounts[2] != rejectedCount) {
            setState(() {
              _refundCounts[0] = pendingCount;
              _refundCounts[1] = approvedCount;
              _refundCounts[2] = rejectedCount;
            });
          }
        });

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyStateCard(
              icon: Icons.assignment_return_outlined,
              iconColor: cs.tertiary,
              title: 'Tidak ada Refund ${_refundFilterLabels[_refundFilter]}',
              subtitle: 'Pengembalian dana buyer dengan status\n"${_refundFilterLabels[_refundFilter]}" akan muncul di sini.',
              cs: cs,
              tt: tt,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final payout = filtered[index];
              return _PayoutRequestCard(payout: payout);
            },
            childCount: filtered.length,
          ),
        );
      },
    );
  }
}

class _PayoutRequestCard extends ConsumerWidget {
  const _PayoutRequestCard({required this.payout});
  final PayoutModel payout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(payout.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Request dari ${payout.userName}',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                dateStr,
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${payout.bankName} - ${payout.bankAccountNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('a.n. ${payout.bankAccountName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(
                  rupiah.format(payout.amount),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), fontSize: 14),
                ),
              ],
            ),
          ),
          if (payout.status == PayoutStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApprove(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  payout.status == PayoutStatus.approved ? Icons.check_circle : Icons.cancel,
                  color: payout.status == PayoutStatus.approved ? const Color(0xFF2E7D32) : cs.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  payout.status == PayoutStatus.approved ? 'Telah disetujui' : 'Ditolak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: payout.status == PayoutStatus.approved ? const Color(0xFF2E7D32) : cs.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(payoutRepositoryProvider).approvePayout(payout.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout disetujui')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final noteCtrl = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Payout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saldo akan dikembalikan ke dompet user. Sertakan alasan:'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Alasan penolakan', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      try {
        await ref.read(payoutRepositoryProvider).rejectPayout(payout.id, payout.userId, payout.amount, note: noteCtrl.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout ditolak, saldo dikembalikan')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────────
class _SummaryBanner extends ConsumerWidget {
  const _SummaryBanner({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerPayoutsAsync = ref.watch(payoutsByRoleProvider('seller'));
    final buyerPayoutsAsync = ref.watch(payoutsByRoleProvider('buyer'));

    final sellerPayouts = sellerPayoutsAsync.value ?? [];
    final buyerPayouts = buyerPayoutsAsync.value ?? [];

    final pendingPayoutsCount = sellerPayouts.where((p) => p.status == PayoutStatus.pending).length;
    final pendingRefundsCount = buyerPayouts.where((p) => p.status == PayoutStatus.pending).length;

    double totalAmount = 0;
    for (final p in sellerPayouts) {
      if (p.status == PayoutStatus.pending) totalAmount += p.amount;
    }
    for (final p in buyerPayouts) {
      if (p.status == PayoutStatus.pending) totalAmount += p.amount;
    }

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final totalAmountStr = formatCurrency.format(totalAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'VERIFY PAYOUT',
                style: tt.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BannerStat(
                  label: 'Total Payout\nPending',
                  value: pendingPayoutsCount.toString(),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _BannerStat(
                  label: 'Total Refund\nPending',
                  value: pendingRefundsCount.toString(),
                  icon: Icons.assignment_return_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _BannerStat(
                  label: 'Total Dana\n(Rp)',
                  value: totalAmountStr,
                  icon: Icons.attach_money_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ── Empty State Card ──────────────────────────────────────────────────────────
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.cs,
    required this.tt,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, size: 36, color: iconColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
