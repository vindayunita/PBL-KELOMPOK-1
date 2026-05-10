import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/buyer_dashboard/data/admin_order_repository.dart';
import '../../../../features/courier_dashboard/domain/courier_application_providers.dart';
import '../../../../features/seller_registration/domain/seller_application_providers.dart';

// ── Main Widget ───────────────────────────────────────────────────────────────
class AdminAlertsScreen extends ConsumerWidget {
  /// Called when user taps an alert card.
  /// [screenIndex] : 1=Verify, 2=Payout
  /// [tabIndex]    : sub-tab index within that screen
  const AdminAlertsScreen({super.key, required this.onNavigateTo});

  final void Function(int screenIndex, int tabIndex) onNavigateTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ── Live data ──
    final sellerAsync  = ref.watch(allSellerApplicationsProvider(null));
    final courierAsync = ref.watch(allCourierApplicationsProvider(null));

    final pendingSellers  =
        sellerAsync.value?.where((a) => a.isPending).length ?? 0;
    final pendingCouriers =
        courierAsync.value?.where((a) => a.isPending).length ?? 0;

    // Live payment pending count
    final paymentAsync = ref.watch(
        allOrdersStreamProvider(status: 'pending_verification'));
    final pendingPayments = paymentAsync.value?.length ?? 0;

    // Placeholder counts — replace when real models are wired
    const pendingRefunds       = 0;
    const pendingPayoutSellers = 0;
    const pendingRefundProcess = 0;

    final totalPending = pendingSellers +
        pendingCouriers +
        pendingPayments +
        pendingRefunds +
        pendingPayoutSellers +
        pendingRefundProcess;

    // screenIndex → which bottom nav tab; tabIndex → sub-tab inside that screen
    // Verify tabs: Courier=0, Payment=1, Refund=2, Seller=3
    // Payout tabs:  Payout Seller=0, Refund Processing=1
    final alerts = <_AlertItem>[
      _AlertItem(
        category:        'Verify Courier',
        description:     'Pendaftaran kurir baru menunggu verifikasi',
        count:           pendingCouriers,
        icon:            Icons.delivery_dining_rounded,
        color:           const Color(0xFF0277BD),
        tag:             'VERIFY',
        screenIndex:     1,
        tabIndex:        0,
      ),
      _AlertItem(
        category:        'Verify Seller',
        description:     'Pendaftaran seller baru menunggu verifikasi',
        count:           pendingSellers,
        icon:            Icons.storefront_rounded,
        color:           const Color(0xFF6A1B9A),
        tag:             'VERIFY',
        screenIndex:     1,
        tabIndex:        3,
      ),
      _AlertItem(
        category:        'Verify Payment',
        description:     'Transaksi pembayaran menunggu konfirmasi',
        count:           pendingPayments,
        icon:            Icons.credit_card_rounded,
        color:           const Color(0xFF00695C),
        tag:             'VERIFY',
        screenIndex:     1,
        tabIndex:        1,
      ),
      _AlertItem(
        category:        'Verify Refund',
        description:     'Klaim refund dari buyer menunggu review',
        count:           pendingRefunds,
        icon:            Icons.assignment_return_rounded,
        color:           const Color(0xFFBF360C),
        tag:             'VERIFY',
        screenIndex:     1,
        tabIndex:        2,
      ),
      _AlertItem(
        category:        'Payout Seller',
        description:     'Pencairan dana seller menunggu diproses',
        count:           pendingPayoutSellers,
        icon:            Icons.account_balance_wallet_rounded,
        color:           const Color(0xFF1565C0),
        tag:             'PAYOUT',
        screenIndex:     2,
        tabIndex:        0,
      ),
      _AlertItem(
        category:        'Refund Processing',
        description:     'Pengembalian dana buyer menunggu diproses',
        count:           pendingRefundProcess,
        icon:            Icons.currency_exchange_rounded,
        color:           const Color(0xFF2E7D32),
        tag:             'PAYOUT',
        screenIndex:     2,
        tabIndex:        1,
      ),
    ];

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
                  child:
                      Icon(Icons.sync_rounded, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text('EcoTrade',
                    style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: cs.onSurface)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('ADMIN',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onError,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      )),
                ),
              ],
            ),
            actions: [
              if (totalPending > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.white, size: 7),
                        const SizedBox(width: 5),
                        Text(
                          '$totalPending Pending',
                          style: tt.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Banner ──
                  _HeroBanner(cs: cs, tt: tt, totalPending: totalPending),

                  const SizedBox(height: 24),

                  // ── Section Label ──
                  Text(
                    'NOTIFIKASI SISTEM',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pending Alerts',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ketuk item di bawah untuk langsung menuju ke menu terkait.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Alert Cards ──
                  ...alerts.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AlertCard(
                          item: item,
                          cs: cs,
                          tt: tt,
                          onTap: () =>
                              onNavigateTo(item.screenIndex, item.tabIndex),
                        ),
                      )),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.cs,
    required this.tt,
    required this.totalPending,
  });
  final ColorScheme cs;
  final TextTheme tt;
  final int totalPending;

  @override
  Widget build(BuildContext context) {
    final hasAlerts = totalPending > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAlerts
              ? [cs.error, cs.error.withValues(alpha: 0.7)]
              : [cs.primary, cs.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (hasAlerts ? cs.error : cs.primary).withValues(alpha: 0.3),
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
                child: Icon(
                  hasAlerts
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hasAlerts ? 'ADA ITEM PENDING' : 'SEMUA BERSIH',
                style: tt.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$totalPending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasAlerts
                ? 'Item masih menunggu tindakan Anda'
                : 'Tidak ada item yang perlu ditindaklanjuti',
            style: tt.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniBadge(label: 'Verify', icon: Icons.fact_check_rounded),
              const SizedBox(width: 8),
              _MiniBadge(label: 'Payout', icon: Icons.payments_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert Data Model ──────────────────────────────────────────────────────────
class _AlertItem {
  const _AlertItem({
    required this.category,
    required this.description,
    required this.count,
    required this.icon,
    required this.color,
    required this.tag,
    required this.screenIndex,
    required this.tabIndex,
  });
  final String category;
  final String description;
  final int count;
  final IconData icon;
  final Color color;
  final String tag;        // 'VERIFY' or 'PAYOUT'
  final int screenIndex;   // 1=Verify, 2=Payout
  final int tabIndex;      // sub-tab inside that screen
}

// ── Alert Card ────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.item,
    required this.cs,
    required this.tt,
    required this.onTap,
  });
  final _AlertItem item;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPending = item.count > 0;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasPending
                  ? item.color.withValues(alpha: 0.4)
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: hasPending ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hasPending
                    ? item.color.withValues(alpha: 0.08)
                    : cs.shadow.withValues(alpha: 0.04),
                blurRadius: hasPending ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon ──
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: item.color
                      .withValues(alpha: hasPending ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: item.color
                      .withValues(alpha: hasPending ? 1.0 : 0.5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.tag == 'VERIFY'
                                ? cs.primaryContainer
                                : cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.tag,
                            style: tt.labelSmall?.copyWith(
                              color: item.tag == 'VERIFY'
                                  ? cs.onPrimaryContainer
                                  : cs.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.category,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Count + Arrow ──
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: hasPending
                          ? item.color
                          : cs.surfaceContainerLow,
                      shape: BoxShape.circle,
                      boxShadow: hasPending
                          ? [
                              BoxShadow(
                                color:
                                    item.color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.count}',
                      style: TextStyle(
                        color: hasPending
                            ? Colors.white
                            : cs.onSurface.withValues(alpha: 0.35),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasPending ? 'pending' : 'clear',
                        style: tt.labelSmall?.copyWith(
                          color: hasPending
                              ? item.color
                              : cs.onSurface.withValues(alpha: 0.35),
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: hasPending
                            ? item.color
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
