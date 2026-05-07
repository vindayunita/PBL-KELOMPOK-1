import 'package:flutter/material.dart';

// ── Main Widget ───────────────────────────────────────────────────────────────
class AdminPayoutScreen extends StatefulWidget {
  const AdminPayoutScreen({super.key, this.tabNotifier});

  /// Optional notifier — set its value to jump to a tab from outside.
  final ValueNotifier<int>? tabNotifier;

  @override
  State<AdminPayoutScreen> createState() => _AdminPayoutScreenState();
}

class _AdminPayoutScreenState extends State<AdminPayoutScreen> {
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
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sync_rounded, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'EcoTrade',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ADMIN',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onError,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
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

  // ── Payout Content ───────────────────────────────────────────────────────────
  Widget _buildPayoutContent(
      BuildContext context, ColorScheme cs, TextTheme tt) {
    // TODO: Replace with real data list when model is ready
    return SliverToBoxAdapter(
      child: _EmptyStateCard(
        icon: Icons.account_balance_wallet_outlined,
        iconColor: cs.primary,
        title:
            'Tidak ada Payout ${_payoutFilterLabels[_payoutFilter]}',
        subtitle:
            'Permintaan pencairan dana seller dengan status\n"${_payoutFilterLabels[_payoutFilter]}" akan muncul di sini.',
        cs: cs,
        tt: tt,
      ),
    );
  }

  // ── Refund Content ────────────────────────────────────────────────────────────
  Widget _buildRefundContent(
      BuildContext context, ColorScheme cs, TextTheme tt) {
    // TODO: Replace with real data list when model is ready
    return SliverToBoxAdapter(
      child: _EmptyStateCard(
        icon: Icons.assignment_return_outlined,
        iconColor: cs.tertiary,
        title:
            'Tidak ada Refund ${_refundFilterLabels[_refundFilter]}',
        subtitle:
            'Pengembalian dana buyer dengan status\n"${_refundFilterLabels[_refundFilter]}" akan muncul di sini.',
        cs: cs,
        tt: tt,
      ),
    );
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
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
                  value: '0',
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
                  value: '0',
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
                  value: '0',
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
