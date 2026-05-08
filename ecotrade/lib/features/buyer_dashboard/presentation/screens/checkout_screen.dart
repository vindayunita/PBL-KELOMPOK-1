import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/user/domain/user_providers.dart';
import '../../data/cart_item_model.dart';
import '../../data/cart_repository.dart';
import '../../data/order_item_model.dart';
import '../../data/order_repository.dart';
import 'manage_address_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CheckoutScreen — accepts a list of OrderItems (from cart or direct buy)
// ─────────────────────────────────────────────────────────────────────────────
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    this.clearCartAfterOrder = false,
  });

  /// Items to purchase — built from CartItemModel or direct ProductModel.
  final List<OrderItem> items;

  /// If true, the cart Firestore collection will be cleared after a successful order.
  final bool clearCartAfterOrder;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _picker = ImagePicker();

  Uint8List? _proofBytes;
  String? _proofExt;
  bool _isLoading = false;

  // ── Price helpers ──────────────────────────────────────────────────────────
  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  double get _total => widget.items.fold(0.0, (s, i) => s + i.subtotal);

  // ── Pick image from gallery ────────────────────────────────────────────────
  Future<void> _pickProof() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    final ext = xfile.name.split('.').last.toLowerCase();
    setState(() {
      _proofBytes = bytes;
      _proofExt = ext.isEmpty ? 'jpg' : ext;
    });
  }

  // ── Place Order ────────────────────────────────────────────────────────────
  Future<void> _placeOrder(
      BuildContext context, String deliveryAddress) async {
    if (deliveryAddress.isEmpty) {
      _snack(context, 'Tambahkan alamat pengiriman terlebih dahulu',
          isError: true);
      return;
    }
    if (_proofBytes == null) {
      _snack(context, 'Upload bukti pembayaran terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo =
          ProviderScope.containerOf(context).read(orderRepositoryProvider);

      final proofUrl =
          await repo.uploadPaymentProof(_proofBytes!, _proofExt ?? 'jpg');

      await repo.placeOrder(
        items: widget.items,
        buyerAddress: deliveryAddress,
        total: _total,
        paymentProofUrl: proofUrl,
      );

      if (widget.clearCartAfterOrder && context.mounted) {
        await ProviderScope.containerOf(context)
            .read(cartRepositoryProvider)
            .clearCart();
      }

      if (!context.mounted) return;
      _showSuccess(context);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Gagal memproses pesanan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(BuildContext ctx, String msg, {bool isError = false}) {
    final cs = Theme.of(ctx).colorScheme;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? cs.error : cs.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  void _showSuccess(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: cs.secondary, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Pesanan Berhasil!',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'Pesanan Anda sedang diverifikasi. Admin akan menghubungi Anda segera.',
              textAlign: TextAlign.center,
              style:
                  tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
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
                  Navigator.of(ctx)
                    ..pop()
                    ..pop();
                },
                child: const Text('Kembali ke Market',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Watch the current user's Firestore document for address data
    final userAsync = ref.watch(currentUserDocProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Checkout',
            style: tt.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          // Find the default address or the first one; null if empty map
          final addresses = user?.addresses ?? [];
          final _found = addresses.firstWhere(
            (a) => a['isDefault'] == true,
            orElse: () => addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
          );
          final Map<String, dynamic>? defaultAddr =
              _found.isEmpty ? null : _found;

          // Build the delivery address string
          String deliveryAddress = '';
          if (defaultAddr != null) {
            final parts = [
              defaultAddr['detail'] as String? ?? '',
              defaultAddr['city'] as String? ?? '',
              defaultAddr['postalCode'] as String? ?? '',
            ].where((s) => s.isNotEmpty).toList();
            deliveryAddress = parts.join(', ');
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Delivery Address ───────────────────────────────────
                      _buildAddressSection(
                          context, cs, tt, defaultAddr, deliveryAddress),
                      const SizedBox(height: 16),

                      // ── Payment Verification ───────────────────────────────
                      Text('VERIFIKASI PEMBAYARAN',
                          style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 10),
                      _buildBankDetails(cs, tt),
                      const SizedBox(height: 12),
                      _buildUploadProof(cs, tt),
                      const SizedBox(height: 20),

                      // ── Order Summary ──────────────────────────────────────
                      Text('RINGKASAN PESANAN',
                          style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      ...widget.items
                          .map((item) => _buildOrderItem(item, cs, tt)),
                      const SizedBox(height: 12),
                      Divider(color: cs.outlineVariant, height: 1),
                      const SizedBox(height: 12),
                      _summaryRow(
                          'Subtotal', 'Rp ${_fmt(_total)}', cs, tt),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pembayaran',
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text('Rp ${_fmt(_total)}',
                              style: tt.headlineSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Place Order button ─────────────────────────────────────────
              _buildPlaceOrderBar(context, cs, tt, deliveryAddress),
            ],
          );
        },
      ),
    );
  }

  // ── Delivery Address Section ───────────────────────────────────────────────

  Widget _buildAddressSection(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Map<String, dynamic>? defaultAddr,
    String deliveryAddress,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on_outlined,
                    size: 20, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Alamat Pengiriman',
                    style: tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              // Edit / Manage button
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ManageAddressScreen()));
                  // Riverpod stream will auto-refresh after navigation
                },
                icon: Icon(
                  defaultAddr == null
                      ? Icons.add_rounded
                      : Icons.edit_outlined,
                  size: 16,
                ),
                label: Text(defaultAddr == null ? 'Tambah' : 'Ubah'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (defaultAddr != null) ...[
            // Show label badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_outlined,
                          size: 13, color: cs.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        defaultAddr['label'] as String? ?? 'Alamat',
                        style: tt.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (defaultAddr['isDefault'] == true) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Utama',
                        style: tt.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              deliveryAddress,
              style: tt.bodyMedium?.copyWith(height: 1.5),
            ),
          ] else ...[
            // No address — prompt
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: cs.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: cs.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada alamat tersimpan. Tambahkan alamat pengiriman agar pesanan dapat diproses.',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onErrorContainer, height: 1.5),
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

  // ── Bank Details ───────────────────────────────────────────────────────────

  Widget _buildBankDetails(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text('DETAIL TRANSFER BANK',
                  style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _bankField('NAMA BANK', 'Global Green Bank', cs, tt)),
              const SizedBox(width: 16),
              Expanded(
                  child: _bankField(
                      'NOMOR REKENING', '8820-4491-0021-9382', cs, tt)),
            ],
          ),
          const SizedBox(height: 12),
          _bankField('ATAS NAMA', 'EcoTrade International Ltd.', cs, tt),
        ],
      ),
    );
  }

  Widget _bankField(String label, String value, ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontSize: 9)),
        const SizedBox(height: 3),
        Text(value,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Upload Proof ───────────────────────────────────────────────────────────

  Widget _buildUploadProof(ColorScheme cs, TextTheme tt) {
    return GestureDetector(
      onTap: _pickProof,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: _proofBytes != null
              ? cs.secondaryContainer.withValues(alpha: 0.4)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _proofBytes != null ? cs.secondary : cs.outlineVariant,
            width: _proofBytes != null ? 1.5 : 1,
          ),
        ),
        child:
            _proofBytes != null ? _proofPreview(cs, tt) : _proofPlaceholder(cs, tt),
      ),
    );
  }

  Widget _proofPlaceholder(ColorScheme cs, TextTheme tt) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.cloud_upload_outlined,
              size: 32, color: cs.onPrimaryContainer),
        ),
        const SizedBox(height: 14),
        Text('Upload Bukti Pembayaran',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Tap untuk memilih foto dari galeri.',
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }

  Widget _proofPreview(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(_proofBytes!,
              width: 72, height: 72, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bukti pembayaran dipilih',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Tap untuk ganti gambar',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, color: cs.secondary, size: 24),
      ],
    );
  }

  // ── Order Item Row ─────────────────────────────────────────────────────────

  Widget _buildOrderItem(OrderItem item, ColorScheme cs, TextTheme tt) {
    final isSample = item.purchaseType == 'sample';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              color: cs.surfaceContainerHigh,
              child: item.productImageUrl.isNotEmpty
                  ? Image.network(item.productImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_outlined,
                          color: cs.onSurfaceVariant))
                  : Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productTitle,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSample
                            ? cs.tertiaryContainer
                            : cs.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSample ? 'SAMPLE' : 'STANDARD',
                        style: tt.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSample
                                ? cs.onTertiaryContainer
                                : cs.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${item.quantity} ${item.unit}',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('Rp ${_fmt(item.subtotal)}',
              style: tt.titleSmall
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text(value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Place Order Bar ────────────────────────────────────────────────────────

  Widget _buildPlaceOrderBar(
      BuildContext context, ColorScheme cs, TextTheme tt, String deliveryAddress) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed:
              _isLoading ? null : () => _placeOrder(context, deliveryAddress),
          child: _isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(cs.onPrimary)),
                )
              : Text('Buat Pesanan',
                  style: tt.titleSmall?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: build OrderItem list from CartItemModel list
// ─────────────────────────────────────────────────────────────────────────────
List<OrderItem> cartItemsToOrderItems(List<CartItemModel> cartItems) {
  return cartItems
      .map((c) => OrderItem(
            productId: c.productId,
            productTitle: c.productTitle,
            productImageUrl: c.productImageUrl,
            purchaseType: c.purchaseType,
            unitPrice: c.effectiveUnitPrice,
            quantity: c.quantity,
            unit: c.unit,
            sellerId: c.sellerId,
            sellerName: c.sellerName,
          ))
      .toList();
}
