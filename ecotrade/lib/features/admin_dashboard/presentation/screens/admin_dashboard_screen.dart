import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/domain/auth_providers.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = user?.displayName ?? user?.email ?? 'Admin';

    final List<Widget> _tabs = [
      // Index 0 — Home / Dashboard
      _DashboardTab(
        displayName: displayName,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      // Index 1 — Verify
      const _VerifyTab(),
      // Index 2 — Payout (placeholder)
      const Center(child: Text('Payout')),
      // Index 3 — Alerts (placeholder)
      const Center(child: Text('Alerts')),
      // Index 4 — Profile
      const AdminProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      // ── Bottom Nav ──
      bottomNavigationBar: NavigationBar(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Verify',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Payout',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.displayName,
    required this.colorScheme,
    required this.textTheme,
  });

  final String displayName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: colorScheme.surfaceContainerLowest,
            floating: true,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sync_rounded,
                      color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'EcoTrade',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ADMIN',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
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
                    childAspectRatio: 1.45,
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
                        label: 'New Products',
                        value: '0',
                        icon: Icons.inventory_2_outlined,
                        color: colorScheme.secondary,
                        onTap: () {},
                        actionLabel: 'Review Queue',
                      ),
                      _AdminStatCard(
                        label: 'Total Pending',
                        value: 'Rp 0,-',
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada aktivitas tercatat.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Log akan muncul saat ada transaksi,\nverifikasi, atau perubahan sistem.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
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
    this.badge,
    this.badgeColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String actionLabel;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onError,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
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
            const SizedBox(height: 6),
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

// ── Activity Item ─────────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isNew,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
              if (isNew) ...[
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Verify Tab ───────────────────────────────────────────────────────────────
class _VerifyTab extends StatefulWidget {
  const _VerifyTab();

  @override
  State<_VerifyTab> createState() => _VerifyTabState();
}

class _VerifyTabState extends State<_VerifyTab> {
  int _filterIndex = 0;
  final List<String> _filters = ['Product', 'Courier', 'Payment', 'Refund'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MARKET INTEGRITY',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending Approvals',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review incoming material batches for sustainability\ncompliance and trade readiness.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filter chips ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final selected = i == _filterIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _filters[i],
                              style: textTheme.labelMedium?.copyWith(
                                color: selected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withOpacity(0.65),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Empty State ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tidak ada item menunggu verifikasi.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Semua ${_filters[_filterIndex].toLowerCase()} telah diproses\natau belum ada yang masuk.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
