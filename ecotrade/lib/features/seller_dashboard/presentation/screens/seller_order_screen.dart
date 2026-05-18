import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/buyer_dashboard/data/order_model.dart';
import '../../data/seller_order_repository.dart';

class SellerOrderScreen extends ConsumerStatefulWidget {
  const SellerOrderScreen({super.key});

  @override
  ConsumerState<SellerOrderScreen> createState() => _SellerOrderScreenState();
}

class _SellerOrderScreenState extends ConsumerState<SellerOrderScreen> {
  static const Color primaryBlue   = Color(0xFF005DA7);
  static const Color primaryGreen  = Color(0xFFB9EEAB);
  static const Color darkGreen     = Color(0xFF3B6934);
  static const Color greyText      = Color(0xFF888888);
  static const Color appBackground = Color(0xFFF7F7F7);

  int _selectedCategory = 0;
  final List<String> _categories = ['Order', 'Return', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    final incomingAsync   = ref.watch(sellerIncomingOrdersProvider);
    final completedAsync  = ref.watch(sellerCompletedOrdersProvider);
    final returnAsync     = ref.watch(sellerReturnOrdersProvider);

    // Jumlah item berdasarkan tab aktif
    int itemCount = 0;
    if (_selectedCategory == 0) itemCount = incomingAsync.value?.length ?? 0;
    if (_selectedCategory == 1) itemCount = returnAsync.value?.length ?? 0;
    if (_selectedCategory == 2) itemCount = completedAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: appBackground,

      // ── APP BAR ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: const Text(
          'EcoTrade',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ],
      ),

      // ── BODY ──
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Tab Kategori ──
          Row(
            children: List.generate(_categories.length, (index) {
              final selected = _selectedCategory == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < _categories.length - 1 ? 10 : 0),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedCategory = index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected ? primaryBlue : Colors.white,
                      foregroundColor: selected ? Colors.white : Colors.black87,
                      elevation: selected ? 2 : 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: selected ? primaryBlue : const Color(0xFFE0E0E0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _categories[index],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // ── Judul + hitungan item ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _selectedCategory == 0
                    ? 'Order Masuk'
                    : _selectedCategory == 1
                        ? 'Return Requests'
                        : 'Pesanan Selesai',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                '$itemCount ITEM',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: darkGreen),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Content ──
          if (_selectedCategory == 0)
            incomingAsync.when(
              loading: () => _buildLoadingState(),
              error:   (e, _) => _buildErrorState(e.toString()),
              data:    (orders) => orders.isEmpty
                  ? _buildOrderEmptyState()
                  : Column(
                      children: orders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildFirestoreOrderCard(
                          context: context,
                          order: order,
                          showActions: order.status == OrderStatus.verified,
                        ),
                      )).toList(),
                    ),
            )
          else if (_selectedCategory == 1)
            returnAsync.when(
              loading: () => _buildLoadingState(),
              error:   (e, _) => _buildErrorState(e.toString()),
              data:    (orders) => orders.isEmpty
                  ? _buildReturnEmptyState()
                  : Column(
                      children: orders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildReturnCard(order: order),
                      )).toList(),
                    ),
            )
          else
            completedAsync.when(
              loading: () => _buildLoadingState(),
              error:   (e, _) => _buildErrorState(e.toString()),
              data:    (orders) => orders.isEmpty
                  ? _buildCompletedEmptyState()
                  : Column(
                      children: orders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildFirestoreOrderCard(
                          context: context,
                          order: order,
                          showActions: false,
                        ),
                      )).toList(),
                    ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Order card dari Firestore ──────────────────────────────────────────────
  Widget _buildFirestoreOrderCard({
    required BuildContext context,
    required OrderModel order,
    required bool showActions,
  }) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final firstItem = order.firstItem;
    final productName = firstItem?.productTitle ?? 'Produk';
    final productImage = firstItem?.productImageUrl ?? '';
    final qty = firstItem?.quantity ?? 0;
    final unit = firstItem?.unit ?? 'kg';
    final purchaseType = firstItem?.purchaseType ?? '';
    final price = fmt.format(order.total);

    final isVerified   = order.status == OrderStatus.verified;
    final isProcessing = order.status == OrderStatus.processing;
    final isAssigned   = order.status == OrderStatus.assigned;   // kurir ditugaskan, belum terima
    final isPickedUp   = order.status == OrderStatus.pickedUp;   // kurir sudah terima (dalam perjalanan)
    final isComplete   = order.status == OrderStatus.completed;  // pesanan selesai

    final badgeLabel = isVerified
        ? 'Baru'
        : isProcessing
            ? 'Dikemas'
            : isAssigned
                ? 'Kurir Ditugaskan'
                : isPickedUp
                    ? 'Dalam Perjalanan'
                    : order.status.label;
    final badgeBg = isVerified || isProcessing || isPickedUp
        ? const Color(0xFFDCEEFF)
        : isAssigned
            ? const Color(0x1A2976C7)
            : primaryGreen;
    final badgeText = isVerified || isProcessing || isPickedUp
        ? primaryBlue
        : isAssigned
            ? const Color(0xFF005DA7)
            : darkGreen;

    // Tipe pembelian
    final typeLabel = purchaseType.toLowerCase() == 'sample' ? 'Sample' : 'Standard';
    final typeBg    = purchaseType.toLowerCase() == 'sample'
        ? const Color(0x1A00581C) : const Color(0xFFE8F5E9);
    final typeColor = purchaseType.toLowerCase() == 'sample'
        ? const Color(0xFF00581C) : const Color(0xFF2E7D32);

    const labelStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: Color(0xFF717783), letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Row utama: Gambar (kiri) + semua info (kanan) ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // product image
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: productImage.isNotEmpty
                ? Image.network(productImage, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey, size: 30))
                : const Icon(Icons.image_outlined, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: 14),

          // Kolom kanan: nama+badge, Standard/Sample, TOTAL PESANAN, TOTAL HARGA
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Nama produk + Badge status sejajar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Badge status tidak ditampilkan di tab Selesai
                  if (!isComplete) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeText,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Tipe pembelian (Standard / Sample)
              if (purchaseType.isNotEmpty) ...[
                if (purchaseType.toLowerCase() == 'sample')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(5)),
                    child: Text(typeLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor)),
                  )
                else
                  Text(typeLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF717783))),
                const SizedBox(height: 4),
              ],


              // By courier — hanya tampil saat kurir sudah terima (pickedUp)
              if (isPickedUp && order.courierName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'By courier: ${order.courierName}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF717783), fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 4),

              // TOTAL PESANAN — label kiri, nilai kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL PESANAN', style: labelStyle),
                  Text('$qty $unit',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),

              // TOTAL HARGA — label kiri, nilai kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL HARGA', style: labelStyle),
                  Text(price,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue)),
                ],
              ),

              if (order.items.length > 1) ...[
                const SizedBox(height: 4),
                Text('+${order.items.length - 1} produk lainnya',
                    style: const TextStyle(fontSize: 11, color: greyText)),
              ],
            ]),
          ),
        ]),

        const SizedBox(height: 14),

        if (isVerified)
          // Status BARU: Tolak (kiri) + Terima (kanan)
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleRejectOrder(order),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tolak', style: TextStyle(color: Colors.black87)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAcceptOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Terima'),
              ),
            ),
          ])
        else if (isProcessing)
          // Status DIKEMAS: Tugaskan Kurir (kiri) + Detail (kanan)
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleAssignCourier(order),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: darkGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tugaskan Kurir', style: TextStyle(color: darkGreen, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showOrderDetailSheet(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Detail'),
              ),
            ),
          ])
        else if (isAssigned)
          // Status MENUNGGU KURIR: tombol Tugaskan hilang, hanya Detail
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _showOrderDetailSheet(context, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Detail', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          )
        else if (isComplete)
          // Status SELESAI: Detail (kiri) + Lihat Penilaian (kanan)
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showOrderDetailSheet(context, order),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Detail', style: TextStyle(color: Colors.black87)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showReviewSheet(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Lihat Penilaian', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ])
        else
          // Status DALAM PERJALANAN / lainnya: hanya Detail
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _showOrderDetailSheet(context, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Detail', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }

  // ── Return card dari Firestore ─────────────────────────────────────────────
  Widget _buildReturnCard({required OrderModel order}) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final firstItem    = order.firstItem;
    final productName  = firstItem?.productTitle ?? 'Produk';
    final productImage = firstItem?.productImageUrl ?? '';
    final qty          = firstItem?.quantity ?? 0;
    final unit         = firstItem?.unit ?? 'kg';
    final price        = fmt.format(order.total);

    const labelStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: Color(0xFF717783), letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Badge RETURN merah pojok kiri ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'RETURN',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
          ),
        ),
        const SizedBox(height: 12),

        // ── Row utama: Gambar + Info ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Foto produk
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: productImage.isNotEmpty
                ? Image.network(productImage, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_outlined, color: Colors.grey, size: 30))
                : const Icon(Icons.image_outlined, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: 14),

          // Kolom kanan: nama + total pesanan + total harga
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                productName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL PESANAN', style: labelStyle),
                  Text('$qty $unit',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL HARGA', style: labelStyle),
                  Text(price,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue)),
                ],
              ),
            ]),
          ),
        ]),

        const SizedBox(height: 14),

        // ── Tombol Detail | Tolak | Terima ──
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showOrderDetailSheet(context, order, isReturn: true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Detail', style: TextStyle(color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tolak', style: TextStyle(color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Terima'),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Detail Pesanan Bottom Sheet ───────────────────────────────────────────
  void _showOrderDetailSheet(BuildContext context, OrderModel order, {bool isReturn = false}) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final purchaseType = order.firstItem?.purchaseType ?? 'standard';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Judul + Badge (RETURN / STANDARD) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Detail Pesanan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                // Badge: merah jika return, biru muda jika standard
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isReturn
                        ? Colors.red
                        : const Color(0xFFDCEEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isReturn ? 'RETURN' : purchaseType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isReturn ? Colors.white : primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nama buyer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pembeli',
                    style: TextStyle(fontSize: 13, color: Color(0xFF717783))),
                Text(
                  order.displayBuyerName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Daftar produk
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productTitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Total Pembelian: ${item.quantity} ${item.unit}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF717783)),
                  ),
                ],
              ),
            )),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(
                  fmt.format(order.total),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Alamat pengiriman
            if (order.buyerAddress.isNotEmpty) ...[
              Text(
                'Alamat: ${order.buyerAddress}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF717783), height: 1.5),
              ),
            ],

            // Alasan return (khusus untuk tab Return)
            if (isReturn && order.returnReason != null && order.returnReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Alasan Return: ${order.returnReason}',
                style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Lihat Penilaian Bottom Sheet ──────────────────────────────────────────
  void _showReviewSheet(BuildContext context, OrderModel order) {
    final hasReview = order.reviewText != null && order.reviewText!.isNotEmpty;
    final rating    = order.rating ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            const Text(
              'Penilaian Pembeli',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            if (!hasReview)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Pembeli belum memberikan penilaian.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                ),
              )
            else ...[
              // Bintang rating
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFC107),
                  size: 28,
                )),
              ),
              const SizedBox(height: 12),
              // Teks ulasan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  order.reviewText!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _handleAcceptOrder(OrderModel order) async {
    final repo = ref.read(sellerOrderRepositoryProvider);
    try {
      await repo.acceptOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Order #${order.id.substring(0, 6).toUpperCase()} diterima'),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleRejectOrder(OrderModel order) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Jelaskan alasan...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final repo = ref.read(sellerOrderRepositoryProvider);
    try {
      await repo.rejectOrder(order.id, reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Order ditolak'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleCompleteOrder(OrderModel order) async {
    final repo = ref.read(sellerOrderRepositoryProvider);
    try {
      await repo.completeOrder(order.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🎉 Order selesai!'),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleAssignCourier(OrderModel order) async {
    final repo = ref.read(sellerOrderRepositoryProvider);
    try {
      await repo.assignCourier(order.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🚚 Kurir berhasil ditugaskan!'),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Empty & Loading States ────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text('Error: $msg', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildOrderEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFBBBBBB)),
          SizedBox(height: 16),
          Text('Belum ada orderan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
          SizedBox(height: 6),
          Text(
            'Pesanan dari pembeli yang sudah diverifikasi admin\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.undo_rounded, size: 32, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text('Tidak ada permintaan return',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }

  Widget _buildCompletedEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 46, color: Color(0xFF9CCC65)),
          SizedBox(height: 16),
          Text('Belum ada pesanan selesai',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
          SizedBox(height: 6),
          Text(
            'Pesanan yang sudah selesai akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), height: 1.5),
          ),
        ],
      ),
    );
  }
}
