import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/domain/auth_providers.dart';

part 'buyer_dashboard_screen.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class ProductListing {
  const ProductListing({
    required this.id,
    required this.title,
    required this.price,
    required this.unit,
    required this.badge,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
  });

  final String id;
  final String title;
  final double price;
  final String unit;
  final String badge;
  final String imageUrl;
  final String sellerId;
  final String sellerName;

  factory ProductListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductListing(
      id: doc.id,
      title: data['title'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? 'kg',
      badge: data['badge'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod stream provider — products from Firestore
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
Stream<List<ProductListing>> marketListings(Ref ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ProductListing.fromFirestore).toList());
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class BuyerDashboardScreen extends ConsumerStatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  ConsumerState<BuyerDashboardScreen> createState() =>
      _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState
    extends ConsumerState<BuyerDashboardScreen> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: colorScheme.surfaceContainerLowest,
              elevation: 0,
              floating: true,
              snap: true,
              leadingWidth: 56,
              leading: IconButton(
                icon: Icon(Icons.menu_rounded,
                    color: colorScheme.onSurface, size: 26),
                onPressed: () {},
              ),
              title: Text(
                'EcoTrade',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => _showProfileMenu(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A5C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Search + Filter ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search premium organic waste...',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.45),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: colorScheme.onSurface.withOpacity(0.5),
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero Banner ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HeroBanner(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Market Listings header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Market Listings',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Curated high-yield organic materials',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Product grid ──────────────────────────────────────────────────
            _ProductGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedNavIndex,
        onTap: (i) => setState(() => _selectedNavIndex = i),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text('Sign Out',
                  style: TextStyle(color: colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 180,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0D3B6E), Color(0xFF1565C0)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Eco icon decoration
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.eco_rounded,
                size: 130,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PREMIUM COMMODITY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Trade the Future\nof Carbon.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Browse Origin',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Grid — Firestore stream
// ─────────────────────────────────────────────────────────────────────────────
class _ProductGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(marketListingsProvider);

    return listingsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _EmptyState(
          icon: Icons.error_outline_rounded,
          message: 'Terjadi kesalahan.\nSilakan coba lagi.',
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.storefront_outlined,
              message:
                  'Belum ada produk tersedia.\nTunggu seller mengunggah produk.',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ProductCard(listing: listings[index]),
              childCount: listings.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.7,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.listing});
  final ProductListing listing;

  String get _formattedPrice {
    final formatted = listing.price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: listing.imageUrl.isNotEmpty
                  ? Image.network(
                      listing.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _ImagePlaceholder();
                      },
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _formattedPrice,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${listing.unit}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (listing.badge.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 13, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          listing.badge,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.45),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.storefront_outlined,
     active: Icons.storefront_rounded,
     label: 'MARKET'),
    (icon: Icons.receipt_long_outlined,
     active: Icons.receipt_long_rounded,
     label: 'ORDERS'),
    (icon: Icons.shopping_cart_outlined,
     active: Icons.shopping_cart_rounded,
     label: 'CART'),
    (icon: Icons.person_outline_rounded,
     active: Icons.person_rounded,
     label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final isSelected = i == selectedIndex;
          final item = _items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isSelected ? item.active : item.icon,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withOpacity(0.5),
                      size: 22,
                    ),
                  ),
                  if (!isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}