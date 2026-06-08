import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/product_model.dart';
import '../../../buyer_dashboard/data/review_model.dart';
import '../../../buyer_dashboard/data/order_repository.dart';
import 'seller_edit_komoditi_screen.dart';

final _sellerProdReviewsProvider =
    StreamProvider.autoDispose.family<List<ReviewModel>, String>((ref, id) {
  return ref.read(orderRepositoryProvider).reviewsForProduct(id);
});

class SellerProductPreviewScreen extends ConsumerWidget {
  const SellerProductPreviewScreen({super.key, required this.product});
  final ProductModel product;

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = product;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005DA7),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ),
        title: Text('Detail Produk',
            style: tt.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Foto produk ─────────────────────────────────────────
                  SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: p.imageUrl.isNotEmpty
                        ? Image.network(p.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _Placeholder(cs: cs))
                        : _Placeholder(cs: cs),
                  ),

                  // ── Konten ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(p, cs, tt),
                        const SizedBox(height: 20),
                        _buildPriceStock(p, cs, tt),
                        const SizedBox(height: 20),
                        _divider(cs),
                        _buildDescription(p, cs, tt),
                        _divider(cs),
                        _buildPurchaseTypeInfo(p, cs, tt),
                        _divider(cs),
                        _buildReviews(p, cs, tt, ref),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom bar: Edit ────────────────────────────────────────────
          Container(
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
                    offset: const Offset(0, -4))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => SellerEditKomoditiScreen(product: p))),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: Text('Edit Komoditi',
                    style: tt.titleSmall?.copyWith(
                        color: cs.onPrimary, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
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
                borderRadius: BorderRadius.circular(6)),
            child: Text(p.badge.toUpperCase(),
                style: TextStyle(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.0)),
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
    final fmtStock = p.stock.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Row(children: [
      Expanded(
          child: _InfoCard(
              label: 'PRICE PER KG',
              value: 'Rp ${_fmt(p.price)}',
              valueColor: cs.primary,
              bg: cs.primaryContainer.withValues(alpha: 0.35))),
      const SizedBox(width: 12),
      Expanded(
          child: _InfoCard(
              label: 'STOCK AVAILABLE',
              value: '$fmtStock ${p.unit}',
              valueColor: cs.onSurface,
              bg: cs.surfaceContainerHigh)),
    ]);
  }

  Widget _buildDescription(ProductModel p, ColorScheme cs, TextTheme tt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MATERIAL PROFILE',
          style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
      const SizedBox(height: 10),
      Text(
          p.description.isNotEmpty
              ? p.description
              : 'Tidak ada deskripsi produk.',
          style: tt.bodyMedium
              ?.copyWith(color: cs.onSurface.withValues(alpha: 0.8), height: 1.65)),
    ]);
  }

  Widget _buildPurchaseTypeInfo(ProductModel p, ColorScheme cs, TextTheme tt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PURCHASE TYPE',
          style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _TypeTile(
                label: 'Standard',
                sublabel: 'Rp ${_fmt(p.price)} / ${p.unit}',
                cs: cs,
                tt: tt)),
        const SizedBox(width: 12),
        Expanded(
            child: _TypeTile(
                label: 'Sample (30%)',
                sublabel: 'Rp ${_fmt(p.price * 0.30)} / 1 Kg',
                cs: cs,
                tt: tt)),
      ]),
    ]);
  }

  Widget _buildReviews(
      ProductModel p, ColorScheme cs, TextTheme tt, WidgetRef ref) {
    final reviewsAsync = ref.watch(_sellerProdReviewsProvider(p.id));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ULASAN PEMBELI',
          style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
      const SizedBox(height: 12),
      reviewsAsync.when(
        loading: () => Center(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    color: cs.primary, strokeWidth: 2))),
        error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12)),
            child: Text('Ulasan tidak dapat dimuat',
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Icon(Icons.rate_review_outlined,
                    size: 36, color: cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 8),
                Text('Belum ada ulasan',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4))),
              ]),
            );
          }
          final avg =
              reviews.fold<double>(0, (s, r) => s + r.rating) / reviews.length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Text(avg.toStringAsFixed(1),
                    style: tt.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900, color: cs.primary)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < avg.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFC107),
                              size: 18))),
                  const SizedBox(height: 2),
                  Text('${reviews.length} ulasan',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6))),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            ...reviews.map((r) => _ReviewCard(review: r, cs: cs, tt: tt)),
          ]);
        },
      ),
    ]);
  }

  Widget _divider(ColorScheme cs) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: cs.outlineVariant, thickness: 1, height: 1));
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.label,
      required this.value,
      required this.valueColor,
      required this.bg});
  final String label, value;
  final Color valueColor, bg;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Text(value,
            style: tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: valueColor)),
      ]),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile(
      {required this.label,
      required this.sublabel,
      required this.cs,
      required this.tt});
  final String label, sublabel;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(sublabel,
            style: tt.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
      ]));
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(
      {required this.review, required this.cs, required this.tt});
  final ReviewModel review;
  final ColorScheme cs;
  final TextTheme tt;

  static const _months = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des'
  ];
  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + nama + tanggal + bintang
                Row(children: [
                  CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                          review.buyerName.isNotEmpty
                              ? review.buyerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(review.buyerName,
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(_fmtDate(review.createdAt),
                            style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.45))),
                      ])),
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFC107),
                              size: 14))),
                ]),
                const SizedBox(height: 8),
                // Badge tipe pembelian
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        review.isSample
                            ? Icons.science_outlined
                            : Icons.shopping_bag_outlined,
                        size: 11,
                        color: cs.primary),
                    const SizedBox(width: 4),
                    Text(review.isSample ? 'Sampel' : 'Standard',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.primary)),
                  ]),
                ),
                // Teks ulasan
                if (review.reviewText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(review.reviewText,
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.8),
                          height: 1.5)),
                ],
                // Foto & Video
                if (review.photoUrls.isNotEmpty ||
                    review.videoUrl != null) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ...review.photoUrls.map((url) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: cs.surfaceContainerHigh,
                                  child: Icon(
                                      Icons.broken_image_outlined,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.3)))),
                        )),
                    if (review.videoUrl != null)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8)),
                        child: Stack(alignment: Alignment.center, children: [
                          const Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white, size: 32),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(3)),
                              child: const Text('VIDEO',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ]),
                      ),
                  ]),
                ],
                // Balasan seller
                if (review.sellerReply != null &&
                    review.sellerReply!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Balasan Penjual:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: cs.primary)),
                          const SizedBox(height: 4),
                          Text(review.sellerReply!,
                              style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface
                                      .withValues(alpha: 0.8),
                                  height: 1.4)),
                        ]),
                  ),
                ],
              ])));
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.cs});
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) => Container(
      color: cs.surfaceContainerHigh,
      child: Center(
          child: Icon(Icons.image_outlined,
              size: 48, color: cs.onSurface.withValues(alpha: 0.2))));
}
