import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/domain/auth_providers.dart';
import '../../../../features/buyer_dashboard/data/admin_order_repository.dart';
import '../../../../features/courier_dashboard/domain/courier_application_providers.dart';
import '../../../../features/seller_registration/domain/seller_application_providers.dart';
import '../../data/payout_model.dart';
import '../../domain/payout_providers.dart';
import 'admin_alerts_screen.dart';
import 'admin_payout_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_verify_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Notifiers let Alerts screen jump to a specific tab in Verify/Payout.
  final _verifyTabNotifier = ValueNotifier<int>(0);
  final _payoutTabNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _verifyTabNotifier.dispose();
    _payoutTabNotifier.dispose();
    super.dispose();
  }

  void _navigateFromAlert(int screenIndex, int tabIndex) {
    if (screenIndex == 1) _verifyTabNotifier.value = tabIndex;
    if (screenIndex == 2) _payoutTabNotifier.value = tabIndex;
    setState(() => _selectedIndex = screenIndex);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = user?.displayName ?? user?.email ?? 'Admin';

    // ── Pending counts for red-dot badge ──
    final sellerAsync   = ref.watch(allSellerApplicationsProvider(null));
    final courierAsync  = ref.watch(allCourierApplicationsProvider(null));
    final paymentAsync  = ref.watch(allOrdersStreamProvider(status: 'pending_verification'));
    final sellerPayoutsAsync = ref.watch(payoutsByRoleProvider('seller'));
    final buyerPayoutsAsync  = ref.watch(payoutsByRoleProvider('buyer'));
    final pendingSellers  =
        sellerAsync.value?.where((a) => a.isPending).length ?? 0;
    final pendingCouriers =
        courierAsync.value?.where((a) => a.isPending).length ?? 0;
    final pendingPayments = paymentAsync.value?.length ?? 0;
    final pendingPayoutSellers = sellerPayoutsAsync.value
        ?.where((p) => p.status == PayoutStatus.pending).length ?? 0;
    final pendingRefundProcess = buyerPayoutsAsync.value
        ?.where((p) => p.status == PayoutStatus.pending).length ?? 0;
    final totalPending = pendingSellers + pendingCouriers + pendingPayments
        + pendingPayoutSellers + pendingRefundProcess;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Index 0 — Home Dashboard
          SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              backgroundColor: colorScheme.surfaceContainerLowest,
              floating: true,
              elevation: 0,
              title: Text(
                'Admin Dashboard',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              actions: const [],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Greeting ──
                    Text(
                      'Welcome back,',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      displayName.split(' ').first,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The Global Waste Market is active today',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Stats Grid ──
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.3,
                      children: [
                        // Biru — Verify Courier
                        _AdminStatCard(
                          label: 'Verify Courier',
                          value: '$pendingCouriers',
                          icon: Icons.delivery_dining_rounded,
                          color: const Color(0xFF0277BD),
                          onTap: () => _navigateFromAlert(1, 0),
                          actionLabel: 'Verify Now',
                          isLive: pendingCouriers > 0,
                        ),
                        // Hijau — Verify Payment
                        _AdminStatCard(
                          label: 'Verify Payment',
                          value: '$pendingPayments',
                          icon: Icons.credit_card_rounded,
                          color: const Color(0xFF00695C),
                          onTap: () => _navigateFromAlert(1, 1),
                          actionLabel: 'Approve All',
                          isLive: pendingPayments > 0,
                        ),
                        // Merah — Refund Claims
                        _AdminStatCard(
                          label: 'Refund Claims',
                          value: '$pendingRefundProcess',
                          icon: Icons.assignment_return_rounded,
                          color: colorScheme.error,
                          onTap: () => _navigateFromAlert(2, 1),
                          actionLabel: 'Review Claims',
                          isLive: pendingRefundProcess > 0,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Recent Activity ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Export Logs'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Activity List (Empty State) ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _EmptyActivityState(),
              ),
            ),
          ],
        ),
      ),
          // Index 1 — Verify
          AdminVerifyScreen(tabNotifier: _verifyTabNotifier),
          // Index 2 — Payout
          AdminPayoutScreen(tabNotifier: _payoutTabNotifier),
          // Index 3 — Alerts
          AdminAlertsScreen(onNavigateTo: _navigateFromAlert),
          // Index 4 — Profile
          const AdminProfileScreen(),
        ],
      ),

      // ── Bottom Nav ──
      bottomNavigationBar: NavigationBar(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Verify',
          ),
          const NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Payout',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: totalPending > 0,
              backgroundColor: colorScheme.error,
              smallSize: 8,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: totalPending > 0,
              backgroundColor: colorScheme.error,
              smallSize: 8,
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}

// ── Empty Activity State ──────────────────────────────────────────────────────
class _EmptyActivityState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 32,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Activity Yet',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Activity logs will appear here once\ntransactions or verifications begin.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Admin Stat Card ───────────────────────────────────────────────────────────
class _AdminStatCard extends StatefulWidget {
  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.actionLabel,
    this.isLive = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String actionLabel;
  /// Jika true, tampilkan badge merah berdenyut + border highlight
  final bool isLive;

  @override
  State<_AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<_AdminStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.isLive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AdminStatCard old) {
    super.didUpdateWidget(old);
    if (widget.isLive && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isLive && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final live = widget.isLive;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: live
              ? widget.color.withValues(alpha: 0.13)
              : widget.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: live
                ? widget.color.withValues(alpha: 0.55)
                : widget.color.withValues(alpha: 0.18),
            width: live ? 1.5 : 1.0,
          ),
          boxShadow: live
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon row + live badge ──
            Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const Spacer(),
                if (live)
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: cs.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.error.withValues(alpha: 0.5),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Count value ──
            Text(
              widget.value,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: live ? widget.color : cs.onSurface,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: live ? 0.75 : 0.55),
                fontWeight: live ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // ── Action label ──
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.actionLabel,
                    style: tt.labelSmall?.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded, color: widget.color, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


