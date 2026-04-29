import 'package:flutter/material.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────
class _SellerAccount {
  final String name;
  final String email;
  final String storeName;
  final String phone;
  final String submittedAt;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String idCardUrl;
  final String category;
  final String businessDescription;

  const _SellerAccount({
    required this.name,
    required this.email,
    required this.storeName,
    required this.phone,
    required this.submittedAt,
    required this.status,
    required this.idCardUrl,
    required this.category,
    required this.businessDescription,
  });
}

final _mockSellers = <_SellerAccount>[
  _SellerAccount(
    name: 'Rina Kusuma',
    email: 'rina.kusuma@email.com',
    storeName: 'EcoLeaf Store',
    phone: '0812-3456-7890',
    submittedAt: '29 Apr 2026, 10:15',
    status: 'pending',
    idCardUrl: '',
    category: 'Organic Materials',
    businessDescription:
        'Kami menjual produk berbahan dasar bahan organik alami yang ramah lingkungan, '
        'mulai dari pupuk kompos, sabun herbal, hingga ekstrak tanaman obat. '
        'Semua produk bersertifikat bebas bahan kimia berbahaya.',
  ),
  _SellerAccount(
    name: 'Budi Santoso',
    email: 'budi.santoso@email.com',
    storeName: 'GreenCraft Hub',
    phone: '0857-1122-3344',
    submittedAt: '28 Apr 2026, 14:30',
    status: 'pending',
    idCardUrl: '',
    category: 'Recyclables',
    businessDescription:
        'GreenCraft Hub bergerak di bidang daur ulang material plastik dan logam '
        'menjadi produk kerajinan bernilai tinggi. Kami bekerja sama dengan '
        'komunitas pengepul lokal untuk memastikan rantai pasok yang berkelanjutan.',
  ),
  _SellerAccount(
    name: 'Dewi Rahayu',
    email: 'dewi.rahayu@email.com',
    storeName: 'NaturaMart',
    phone: '0822-9988-7766',
    submittedAt: '27 Apr 2026, 09:00',
    status: 'approved',
    idCardUrl: '',
    category: 'Eco Packaging',
    businessDescription:
        'NaturaMart menyediakan solusi kemasan ramah lingkungan berbahan daur ulang '
        'dan biodegradable untuk pelaku UMKM dan industri skala menengah. '
        'Produk telah lulus uji SNI dan tersertifikasi ekolabel nasional.',
  ),
  _SellerAccount(
    name: 'Andi Wijaya',
    email: 'andi.w@email.com',
    storeName: 'TrashToTreasure',
    phone: '0831-4455-6677',
    submittedAt: '26 Apr 2026, 16:45',
    status: 'rejected',
    idCardUrl: '',
    category: 'Upcycled Goods',
    businessDescription:
        'Usaha upcycling barang bekas menjadi furnitur dan dekorasi rumah. '
        'Bahan baku berasal dari limbah kayu, kain perca, dan botol kaca bekas. '
        'Target pasar adalah konsumen milenial yang peduli lingkungan.',
  ),
];

// ── Main Widget ─────────────────────────────────────────────────────────────
class AdminVerifyScreen extends StatefulWidget {
  const AdminVerifyScreen({super.key});

  @override
  State<AdminVerifyScreen> createState() => _AdminVerifyScreenState();
}

class _AdminVerifyScreenState extends State<AdminVerifyScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  int _sellerFilter = 0; // 0=Pending, 1=Approved, 2=Rejected

  final List<String> _tabs = [
    'Product',
    'Courier',
    'Payment',
    'Refund',
    'Seller',
  ];

  final List<String> _sellerFilterLabels = ['Pending', 'Approved', 'Rejected'];

  List<_SellerAccount> get _filteredSellers {
    final statusMap = ['pending', 'approved', 'rejected'];
    return _mockSellers
        .where((s) => s.status == statusMap[_sellerFilter])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSellerTab = _selectedTab == 4;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main Filter Tabs ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final isSelected = _selectedTab == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTab = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _tabs[i],
                              style: textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withOpacity(0.65),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section Header ──
                  Text(
                    isSellerTab ? 'SELLER MANAGEMENT' : 'MARKET INTEGRITY',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSellerTab
                        ? 'Seller Account Verification'
                        : 'Pending Approvals',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSellerTab
                        ? 'Review and verify new seller account registrations\nbefore they go live on the platform.'
                        : 'Review incoming material batches for sustainability\ncompliance and trade readiness.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.55),
                      height: 1.5,
                    ),
                  ),

                  // ── Seller Sub-filter (only when Seller tab is active) ──
                  if (isSellerTab) ...[
                    const SizedBox(height: 20),
                    _buildSellerFilterBar(colorScheme, textTheme),
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
                ? _buildSellerContent(context)
                : SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Seller Sub-filter Bar ────────────────────────────────────────────────
  Widget _buildSellerFilterBar(ColorScheme colorScheme, TextTheme textTheme) {
    final counts = [
      _mockSellers.where((s) => s.status == 'pending').length,
      _mockSellers.where((s) => s.status == 'approved').length,
      _mockSellers.where((s) => s.status == 'rejected').length,
    ];

    final filterColors = [
      colorScheme.primary,
      const Color(0xFF2E7D32),
      colorScheme.error,
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_sellerFilterLabels.length, (i) {
          final isSelected = _sellerFilter == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sellerFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? filterColors[i] : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: filterColors[i].withOpacity(0.25),
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _sellerFilterLabels[i],
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white.withOpacity(0.85)
                            : colorScheme.onSurface.withOpacity(0.5),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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

  // ── Seller Content ───────────────────────────────────────────────────────
  Widget _buildSellerContent(BuildContext context) {
    final sellers = _filteredSellers;
    if (sellers.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(context));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _SellerCard(
            seller: sellers[index],
            onApprove: sellers[index].status == 'pending'
                ? () => _handleApprove(sellers[index])
                : null,
            onReject: sellers[index].status == 'pending'
                ? () => _handleReject(sellers[index])
                : null,
          ),
        ),
        childCount: sellers.length,
      ),
    );
  }

  void _handleApprove(_SellerAccount seller) {
    // TODO: integrate with backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${seller.storeName} approved successfully'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleReject(_SellerAccount seller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ ${seller.storeName} has been rejected'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Generic Empty State ──────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tabLabel = _selectedTab == 4
        ? _sellerFilterLabels[_sellerFilter]
        : _tabs[_selectedTab];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _tabIcon(_selectedTab),
              size: 36,
              color: colorScheme.primary.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No $tabLabel ${_selectedTab == 4 ? "Sellers" : "Pending"}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTab == 4
                ? 'No seller accounts with "$tabLabel" status.\nNew registrations will appear here for review.'
                : 'All ${_tabs[_selectedTab]} submissions are up to date.\nNew entries will appear here for review.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _tabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.inventory_2_outlined;
      case 1:
        return Icons.local_shipping_outlined;
      case 2:
        return Icons.payments_outlined;
      case 3:
        return Icons.assignment_return_outlined;
      case 4:
        return Icons.person_add_outlined;
      default:
        return Icons.inbox_outlined;
    }
  }
}

// ── Seller Card ──────────────────────────────────────────────────────────────
class _SellerCard extends StatelessWidget {
  final _SellerAccount seller;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _SellerCard({
    required this.seller,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color statusColor;
    if (seller.status == 'approved') {
      statusColor = const Color(0xFF2E7D32);
    } else if (seller.status == 'rejected') {
      statusColor = colorScheme.error;
    } else {
      statusColor = colorScheme.primary;
    }

    String statusLabel;
    if (seller.status == 'approved') {
      statusLabel = 'Approved';
    } else if (seller.status == 'rejected') {
      statusLabel = 'Rejected';
    } else {
      statusLabel = 'Pending';
    }

    IconData statusIcon;
    if (seller.status == 'approved') {
      statusIcon = Icons.check_circle_rounded;
    } else if (seller.status == 'rejected') {
      statusIcon = Icons.cancel_rounded;
    } else {
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    seller.name.isNotEmpty
                        ? seller.name[0].toUpperCase()
                        : '?',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        seller.email,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(
                color: colorScheme.outlineVariant.withOpacity(0.3), height: 1),
            const SizedBox(height: 14),

            // ── Info Grid ──
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _infoChip(
                  context,
                  icon: Icons.storefront_rounded,
                  label: seller.storeName,
                ),
                _infoChip(
                  context,
                  icon: Icons.category_outlined,
                  label: seller.category,
                ),
                _infoChip(
                  context,
                  icon: Icons.phone_outlined,
                  label: seller.phone,
                ),
                _infoChip(
                  context,
                  icon: Icons.schedule_rounded,
                  label: seller.submittedAt,
                ),
              ],
            ),

            // ── Business Description ──
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Deskripsi Bisnis',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    seller.businessDescription,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.75),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // ── Action Buttons (only for pending) ──
            if (seller.status == 'pending') ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(
                            color: colorScheme.error.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
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

  Widget _infoChip(BuildContext context,
      {required IconData icon, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
