import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/domain/auth_providers.dart';
import '../../../../features/buyer_dashboard/data/admin_order_repository.dart';
import '../../../../features/courier_dashboard/domain/courier_application_providers.dart';
import '../../../../features/seller_registration/domain/seller_application_providers.dart';
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
    final pendingSellers  =
        sellerAsync.value?.where((a) => a.isPending).length ?? 0;
    final pendingCouriers =
        courierAsync.value?.where((a) => a.isPending).length ?? 0;
    final pendingPayments = paymentAsync.value?.length ?? 0;
    final totalPending = pendingSellers + pendingCouriers + pendingPayments;

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
                        _AdminStatCard(
                          label: 'Pending Counter',
                          value: '0',
                          icon: Icons.pending_actions_rounded,
                          color: colorScheme.primary,
                          onTap: () {},
                          actionLabel: 'Verify Now',
                        ),
                        _AdminStatCard(
                          label: 'Total Pending',
                          value: 'Rp 0',
                          icon: Icons.payments_outlined,
                          color: colorScheme.tertiary,
                          onTap: () {},
                          actionLabel: 'Approve All',
                        ),
                        _AdminStatCard(
                          label: 'Refund Claims',
                          value: '0',
                          icon: Icons.assignment_return_outlined,
                          color: colorScheme.error,
                          onTap: () {},
                          actionLabel: 'Auth Claims',
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
class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.actionLabel,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    actionLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: color, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

