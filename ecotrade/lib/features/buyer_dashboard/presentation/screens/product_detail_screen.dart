import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cart_repository.dart';
import '../../data/order_item_model.dart';
import '../../../seller_dashboard/domain/product_model.dart';
import 'checkout_screen.dart';

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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom action bar ──────────────────────────────────────────
          _buildBottomBar(context, cs, tt),
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
                    Text('Indonesia',
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
                    'Pembelian sample hanya tersedia 500 gram dengan biaya 30% dari harga normal.',
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

  Widget _buildBottomBar(BuildContext context, ColorScheme cs, TextTheme tt) {
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
            onTap: () => _addToCart(context, cs),
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
              onTap: () => _buyNow(context, cs, tt),
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

  Future<void> _addToCart(BuildContext context, ColorScheme cs) async {
    final p = widget.product;
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

  void _buyNow(BuildContext context, ColorScheme cs, TextTheme tt) {
    final p = widget.product;
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

