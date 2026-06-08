import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cart_repository.dart';
import '../../data/order_item_model.dart';
import '../../data/order_repository.dart';
import '../../data/review_model.dart';
import '../../../seller_dashboard/domain/product_model.dart';
import '../../../user/domain/user_providers.dart';
import 'checkout_screen.dart';
import 'manage_address_screen.dart';

/// Provider stream review untuk satu produk
final _productReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, productId) {
  return ref.read(orderRepositoryProvider).reviewsForProduct(productId);
});

enum PurchaseType { standard, sample }

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final ProductModel product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  PurchaseType _purchaseType = PurchaseType.standard;

  // ── Price helpers ──────────────────────────────────────────────────────────
  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  double get _effectivePrice =>
      _purchaseType == PurchaseType.sample ? widget.product.price * 0.30 : widget.product.price;

  String get _priceBadge {
    final p = _fmt(_effectivePrice);
    return _purchaseType == PurchaseType.sample
        ? 'Rp $p / 1 ${widget.product.unit}'
        : 'Rp $p / ${widget.product.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = widget.product;
    final userAsync = ref.watch(currentUserDocProvider);
    final user = userAsync.value;
    String buyerCity = '';
    if (user != null && user.addresses.isNotEmpty) {
      // Cari alamat default terlebih dahulu; fallback ke address pertama
      final defaultAddr = user.addresses.firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => user.addresses.first,
      );
      buyerCity = defaultAddr['city'] as String? ?? '';
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── App Bar + Hero image ───────────────────────────────────
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: cs.surface,
                  foregroundColor: cs.onSurface,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: cs.onSurface),
                      ),
                    ),
                  ),
                  title: Text('EcoTrade',
                      style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, color: cs.onSurface)),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── Single product image ──────────────────────────
                        p.imageUrl.isNotEmpty
                            ? Image.network(
                                p.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, prog) =>
                                    prog == null ? child : _Placeholder(cs: cs),
                                errorBuilder: (_, __, ___) => _Placeholder(cs: cs),
                              )
                            : _Placeholder(cs: cs),
                        // Gradient fade at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  cs.surfaceContainerLowest,
                                  cs.surfaceContainerLowest.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Content ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + Title
                        _buildHeader(p, cs, tt),
                        const SizedBox(height: 20),

                        // Price + Stock
                        _buildPriceStock(p, cs, tt),
                        const SizedBox(height: 20),
                        _divider(cs),

                        // Description
                        _buildDescription(p, cs, tt),
                        _divider(cs),

                        // Seller card
                        _buildSeller(p, cs, tt),
                        _divider(cs),

                        // Purchase type
                        _buildPurchaseType(p, cs, tt),
                        _divider(cs),

                        // Reviews section
                        _buildReviews(p, cs, tt),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom action bar ──────────────────────────────────────────
          _buildBottomBar(context, cs, tt, buyerCity),
        ],
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildHeader(ProductModel p, ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.badge.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(p.title,
            style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1.15,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(p.commodityType,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildPriceStock(ProductModel p, ColorScheme cs, TextTheme tt) {
    final fmtStock = p.stock
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Row(
      children: [
        Expanded(child: _InfoCard(
          label: 'PRICE PER KG',
          value: 'Rp ${_fmt(p.price)}',
          valueColor: cs.primary,
          bg: cs.primaryContainer.withValues(alpha: 0.35),
        )),
        const SizedBox(width: 12),
        Expanded(child: _InfoCard(
          label: 'STOCK AVAILABLE',
          value: '$fmtStock ${p.unit}',
          valueColor: cs.onSurface,
          bg: cs.surfaceContainerHigh,
        )),
      ],
    );
  }

  Widget _buildDescription(ProductModel p, ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MATERIAL PROFILE',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Text(
          p.description.isNotEmpty ? p.description : 'Tidak ada deskripsi produk.',
          style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.8), height: 1.65),
        ),
      ],
    );
  }

  Widget _buildSeller(ProductModel p, ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.store_rounded, color: cs.onPrimaryContainer, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.sellerName.isNotEmpty ? p.sellerName : 'EcoTrade Seller',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(p.sellerCity,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, size: 16, color: cs.onSecondaryContainer),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseType(ProductModel p, ColorScheme cs, TextTheme tt) {
    final samplePrice = _fmt(p.price * 0.30);
    final standardPrice = _fmt(p.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PURCHASE TYPE',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _TypeCard(
              isSelected: _purchaseType == PurchaseType.standard,
              label: 'Standard',
              sublabel: 'Rp $standardPrice / ${p.unit}',
              cs: cs,
              tt: tt,
              onTap: () => setState(() => _purchaseType = PurchaseType.standard),
            )),
            const SizedBox(width: 12),
            Expanded(child: _TypeCard(
              isSelected: _purchaseType == PurchaseType.sample,
              label: 'Sample (30%)',
              sublabel: 'Rp $samplePrice /1 Kg',
              cs: cs,
              tt: tt,
              onTap: () => setState(() => _purchaseType = PurchaseType.sample),
            )),
          ],
        ),
        if (_purchaseType == PurchaseType.sample) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.tertiary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: cs.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembelian sample hanya tersedia 1 Kg dengan biaya 30% dari harga normal dan hanya bisa satu kali pembelian di setiap toko.',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onTertiaryContainer, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ColorScheme cs, TextTheme tt, String buyerCity) {
    if (widget.product.stock <= 0) {
      return Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 14,
          bottom: MediaQuery.of(context).padding.bottom + 14,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.error.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, color: cs.error),
              const SizedBox(width: 8),
              Text(
                'Maaf, stok produk ini sedang kosong',
                style: tt.labelLarge?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart button
          GestureDetector(
            onTap: () => _addToCart(context, cs, buyerCity),
            child: Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.shopping_cart_outlined,
                  color: cs.onPrimaryContainer, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Buy Now
          Expanded(
            child: GestureDetector(
              onTap: () => _buyNow(context, cs, tt, buyerCity),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, color: cs.onPrimary, size: 20),
                    const SizedBox(width: 6),
                    Text('Beli Sekarang  •  $_priceBadge',
                        style: tt.labelLarge?.copyWith(
                            color: cs.onPrimary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _divider(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: cs.outlineVariant, thickness: 1, height: 1),
      );

  /// Bandingkan dua nama kota secara robust.
  /// Menghapus prefix "Kota", "Kabupaten", "Kab." sebelum membandingkan
  /// sehingga "Kota Surabaya" == "Surabaya", "Kabupaten Malang" == "Malang", dst.
  bool _isSameCity(String buyerCity, String sellerCity) {
    String normalize(String city) => city
        .toLowerCase()
        .replaceFirst(RegExp(r'^(kota|kabupaten|kab\.)\s*'), '')
        .trim();
    return normalize(buyerCity) == normalize(sellerCity);
  }

  Widget _buildReviews(ProductModel p, ColorScheme cs, TextTheme tt) {
    final reviewsAsync = ref.watch(_productReviewsProvider(p.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ULASAN PEMBELI',
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        reviewsAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
            ),
          ),
          error: (e, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 32, color: cs.error.withValues(alpha: 0.7)),
                const SizedBox(height: 8),
                Text('Ulasan tidak dapat dimuat',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 36, color: cs.onSurface.withValues(alpha: 0.25)),
                    const SizedBox(height: 8),
                    Text('Belum ada ulasan untuk produk ini',
                        style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              );
            }

            // Rata-rata rating
            final avgRating = reviews.fold<double>(
                    0, (sum, r) => sum + r.rating) /
                reviews.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: tt.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFC107),
                              size: 18,
                            )),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${reviews.length} ulasan',
                            style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Daftar review
                ...reviews.map((r) => _ReviewCard(review: r, cs: cs, tt: tt)),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showLocationError(BuildContext context, ColorScheme cs) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text(
          'Lokasi Anda tidak sama dengan lokasi penjual. Silakan gunakan alamat di kota yang sama untuk membeli.',
          style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: cs.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _addToCart(BuildContext context, ColorScheme cs, String buyerCity) async {
    final p = widget.product;
    if (p.stock <= 0) return;

    // Check address first
    final userAsync = ref.read(currentUserDocProvider);
    final addresses = userAsync.value?.addresses ?? [];
    if (addresses.isEmpty) {
      _showNoAddressDialog(context, cs);
      return;
    }

    if (!_isSameCity(buyerCity, p.sellerCity)) {
      _showLocationError(context, cs);
      return;
    }

    try {
      await ref.read(cartRepositoryProvider).addToCart(
            productId: p.id,
            productTitle: p.title,
            productImageUrl: p.imageUrl,
            productPrice: p.price,
            unit: p.unit,
            purchaseType:
                _purchaseType == PurchaseType.sample ? 'sample' : 'standard',
            sellerId: p.sellerId,
            sellerName: p.sellerName,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.shopping_cart_rounded, color: cs.onSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${p.title} ditambahkan ke keranjang',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor: cs.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menambah ke keranjang: $e'),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
    }
  }

  void _buyNow(BuildContext context, ColorScheme cs, TextTheme tt, String buyerCity) {
    final p = widget.product;
    if (p.stock <= 0) return;

    // Check address first
    final userAsync = ref.read(currentUserDocProvider);
    final addresses = userAsync.value?.addresses ?? [];
    if (addresses.isEmpty) {
      _showNoAddressDialog(context, cs);
      return;
    }

    if (!_isSameCity(buyerCity, p.sellerCity)) {
      _showLocationError(context, cs);
      return;
    }

    final isSample = _purchaseType == PurchaseType.sample;

    // For sample, quantity is always 1 (fixed 1 Kg) — skip quantity dialog
    if (isSample) {
      final orderItem = OrderItem(
        productId: p.id,
        productTitle: p.title,
        productImageUrl: p.imageUrl,
        purchaseType: 'sample',
        unitPrice: _effectivePrice,
        quantity: 1,
        unit: p.unit,
        sellerId: p.sellerId,
        sellerName: p.sellerName,
      );
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CheckoutScreen(items: [orderItem]),
      ));
      return;
    }

    // Standard — show quantity picker bottom sheet
    _showQuantitySheet(context, cs, tt, p);
  }

  void _showNoAddressDialog(BuildContext context, ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off_rounded,
                  color: cs.onErrorContainer, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Alamat Belum Diatur',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Silakan tambahkan alamat pengiriman terlebih dahulu sebelum melakukan pembelian.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ManageAddressScreen()));
                },
                child: const Text('Atur Alamat Sekarang',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Nanti Saja',
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantitySheet(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    ProductModel p,
  ) {
    // Use a local ValueNotifier so the sheet rebuilds without setState on parent
    final qtyNotifier = ValueNotifier<int>(1);
    final maxStock = p.stock;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text('Jumlah Pembelian',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Stok tersedia: $maxStock ${p.unit}',
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Product preview row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: cs.surfaceContainerHigh,
                      child: (p.imageUrl).isNotEmpty
                          ? Image.network(p.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.image_outlined,
                                  color: cs.onSurfaceVariant))
                          : Icon(Icons.image_outlined,
                              color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title,
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${_fmt(_effectivePrice)} / ${p.unit}',
                          style: tt.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quantity stepper
              ValueListenableBuilder<int>(
                valueListenable: qtyNotifier,
                builder: (_, qty, __) {
                  final subtotal = _effectivePrice * qty;
                  return Column(
                    children: [
                      Row(
                        children: [
                          // Minus
                          _QtyButton(
                            icon: Icons.remove_rounded,
                            cs: cs,
                            enabled: qty > 1,
                            onTap: () {
                              if (qty > 1) qtyNotifier.value = qty - 1;
                            },
                          ),
                          // Value
                          Expanded(
                            child: Center(
                              child: Text(
                                '$qty',
                                style: tt.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          // Plus
                          _QtyButton(
                            icon: Icons.add_rounded,
                            cs: cs,
                            enabled: qty < maxStock,
                            onTap: () {
                              if (qty < maxStock) {
                                qtyNotifier.value = qty + 1;
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Stok hanya tersedia $maxStock ${p.unit}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  backgroundColor: cs.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  margin: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  duration: const Duration(seconds: 2),
                                ));
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Unit label
                      Center(
                        child: Text(
                          '${p.unit}',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Subtotal display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              'Rp ${_fmt(subtotal)}',
                              style: tt.titleMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.of(sheetCtx).pop();
                            final orderItem = OrderItem(
                              productId: p.id,
                              productTitle: p.title,
                              productImageUrl: p.imageUrl,
                              purchaseType: 'standard',
                              unitPrice: _effectivePrice,
                              quantity: qty,
                              unit: p.unit,
                              sellerId: p.sellerId,
                              sellerName: p.sellerName,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                    items: [orderItem]),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 20),
                              const SizedBox(width: 6),
                              Text('Beli Sekarang ($qty ${p.unit})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Quantity +/- Button ────────────────────────────────────────────────────────
class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.cs,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final ColorScheme cs;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? cs.primaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        color: cs.surfaceContainerHigh,
        child: Center(
          child: Icon(Icons.image_outlined, size: 72,
              color: cs.onSurface.withValues(alpha: 0.2)),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bg,
  });
  final String label, value;
  final Color valueColor, bg;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(value,
              style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.isSelected,
    required this.label,
    required this.sublabel,
    required this.cs,
    required this.tt,
    required this.onTap,
  });
  final bool isSelected;
  final String label, sublabel;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface)),
            const SizedBox(height: 4),
            Text(sublabel,
                style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}



// ─── Review Card ──────────────────────────────────────────────────────────────
/// Kartu ulasan individual: avatar inisial, nama, rating, teks, foto, video.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.cs,
    required this.tt,
  });
  final ReviewModel  review;
  final ColorScheme  cs;
  final TextTheme    tt;

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Agt','Sep','Okt','Nov','Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: avatar + nama + tanggal + bintang
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  review.buyerInitial,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.buyerName,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      _fmtDate(review.createdAt),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFFFC107),
                  size: 14,
                )),
              ),
            ],
          ),

          // Badge Standard / Sample
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: review.isSample
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: review.isSample
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF1565C0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.isSample
                          ? Icons.science_rounded
                          : Icons.shopping_bag_rounded,
                      size: 10,
                      color: review.isSample
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.isSample ? 'Sample' : 'Standard',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: review.isSample
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1565C0),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.reviewText,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],

          // Grid foto + thumbnail video dalam satu baris horizontal
          if (review.photoUrls.isNotEmpty ||
              (review.videoUrl != null && review.videoUrl!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Thumbnail foto
                  ...review.photoUrls.map((url) {
                    return GestureDetector(
                      onTap: () => _showFullImage(context, url),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.outlineVariant, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, prog) =>
                                prog == null ? child : Container(
                                  color: cs.surfaceContainerHigh,
                                  child: Center(
                                    child: SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5, color: cs.primary),
                                    ),
                                  ),
                                ),
                            errorBuilder: (_, __, ___) => Container(
                              color: cs.surfaceContainerHigh,
                              child: Icon(Icons.broken_image_outlined,
                                  color: cs.onSurfaceVariant, size: 24),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Thumbnail video (sama ukuran 80×80 dengan foto)
                  if (review.videoUrl != null && review.videoUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () =>
                          _showVideoPlayer(context, review.videoUrl!, cs, tt),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: cs.primary.withValues(alpha: 0.5),
                              width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background gelap
                              Container(
                                color: const Color(0xFF1A1A2E),
                              ),
                              // Ikon play di tengah
                              Center(
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              // Badge "VIDEO" di kiri bawah
                              Positioned(
                                bottom: 5, left: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'VIDEO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white, size: 48),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuka fullscreen video player dialog
  void _showVideoPlayer(
    BuildContext context,
    String videoUrl,
    ColorScheme cs,
    TextTheme tt,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        // Gunakan MediaQuery untuk batasi tinggi maksimum dialog
        final screenH = MediaQuery.of(dialogContext).size.height;
        final maxH    = screenH * 0.75;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                      color: const Color(0xFF1A1A2E),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam_rounded,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Video Ulasan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Video player — Expanded memberi bounded height ke widget
                    Expanded(
                      child: _VideoPlayerWidget(
                        videoUrl: videoUrl,
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Inline Video Player Widget ───────────────────────────────────────────────
class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({
    required this.videoUrl,
    required this.cs,
    required this.tt,
  });
  final String videoUrl;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      _controller.addListener(_onPlayerStateChanged);
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final playing = _controller.value.isPlaying;
    if (playing != _isPlaying) setState(() => _isPlaying = playing);
  }

  void _togglePlay() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      // Restart jika sudah selesai
      if (_controller.value.position >= _controller.value.duration) {
        _controller.seekTo(Duration.zero);
      }
      _controller.play();
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.removeListener(_onPlayerStateChanged);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = widget.tt;

    if (_hasError) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
            const SizedBox(width: 10),
            Text('Gagal memuat video',
                style: tt.labelSmall?.copyWith(color: cs.error)),
          ],
        ),
      );
    }

    if (!_initialized) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: cs.primary),
          ),
        ),
      );
    }

    // Aspect ratio asli dari video; fallback 16:9 jika belum ready
    final aspectRatio = _controller.value.aspectRatio > 0
        ? _controller.value.aspectRatio
        : 16 / 9;

    // Gunakan LayoutBuilder untuk mendapat KEDUA bounded constraint:
    // maxWidth (dari dialog width) dan maxHeight (dari Expanded).
    // Hitung ukuran video yang masuk dalam kedua dimensi (shrink-to-fit).
    const progressBarH = 28.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : availW / aspectRatio + progressBarH;

        // Hitung ukuran video agar tidak melebihi availW maupun (availH - progressBarH)
        double videoW = availW;
        double videoH = videoW / aspectRatio;
        if (videoH > availH - progressBarH) {
          videoH = availH - progressBarH;
          videoW = videoH * aspectRatio;
          // Pastikan tidak melebihi lebar container
          if (videoW > availW) {
            videoW = availW;
            videoH = videoW / aspectRatio;
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Video dengan ukuran yang sudah dihitung — tidak akan overflow
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: videoW,
                height: videoH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(_controller),
                    // Overlay play/pause
                    GestureDetector(
                      onTap: _togglePlay,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: Center(
                          child: Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tap seluruh area saat sedang play
                    if (_isPlaying)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _togglePlay,
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    // Badge label
                    Positioned(
                      top: 8, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('Video Ulasan',
                                style: tt.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Progress bar & scrubbing — tinggi tetap
            SizedBox(
              height: progressBarH,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                colors: VideoProgressColors(
                  playedColor: cs.primary,
                  bufferedColor: cs.primary.withValues(alpha: 0.25),
                  backgroundColor: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
