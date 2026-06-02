import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/notification_badge.dart';
import '../../../../features/buyer_dashboard/data/order_model.dart';
import '../../../../features/buyer_dashboard/data/return_model.dart';
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
    final incomingAsync  = ref.watch(sellerIncomingOrdersProvider);
    final completedAsync = ref.watch(sellerCompletedOrdersProvider);
    final returnAsync    = ref.watch(sellerReturnRequestsProvider);

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
        actions: const [
          NotificationBadge(),
          SizedBox(width: 8),
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
              data:    (returns) => returns.isEmpty
                  ? _buildReturnEmptyState()
                  : Column(
                      children: returns.map((ret) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildReturnCard(ret),
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
    final isAssigned   = order.status == OrderStatus.assigned;
    final isPickedUp   = order.status == OrderStatus.pickedUp;
    final isDelivered  = order.status == OrderStatus.delivered;
    final isComplete   = order.status == OrderStatus.completed;

    final badgeLabel = isVerified
        ? 'Baru'
        : isProcessing
            ? 'Dikemas'
            : isAssigned
                ? 'Kurir Ditugaskan'
                : isPickedUp
                    ? 'Dalam Perjalanan'
                    : isDelivered
                        ? 'Pesanan Tiba'
                        : isComplete
                            ? 'Selesai'
                            : order.status.label;
    final badgeBg = isVerified || isProcessing || isPickedUp
        ? const Color(0xFFDCEEFF)
        : isAssigned
            ? const Color(0x1A2976C7)
            : isDelivered || isComplete
                ? const Color(0xFFDCF5E4)
                : primaryGreen;
    final badgeText = isVerified || isProcessing || isPickedUp
        ? primaryBlue
        : isAssigned
            ? const Color(0xFF005DA7)
            : isDelivered || isComplete
                ? darkGreen
                : darkGreen;

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

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              if (isPickedUp && order.courierName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'By courier: ${order.courierName}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF717783), fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 4),
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
        else if (isAssigned) ...[
          // ── Tracker: Kurir Ditugaskan (menunggu konfirmasi kurir) ──
          _buildDeliveryProgressTracker(
            courierName: order.courierName,
            isWaitingCourier: true,
            isPickedUp: false,
            isDelivered: false,
          ),
          const SizedBox(height: 10),
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
        ] else if (isPickedUp) ...[
          // ── Tracker: Kurir sudah ambil barang (dalam perjalanan) ──
          _buildDeliveryProgressTracker(
            courierName: order.courierName,
            isWaitingCourier: false,
            isPickedUp: true,
            isDelivered: false,
          ),
          const SizedBox(height: 10),
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
        ] else if (isDelivered) ...[
          // ── Tracker: Pesanan tiba di buyer ──
          _buildDeliveryProgressTracker(
            courierName: order.courierName,
            isWaitingCourier: false,
            isPickedUp: true,
            isDelivered: true,
          ),
          const SizedBox(height: 10),
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
        ] else if (isComplete)
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

  // ── Return card (ReturnModel) ──────────────────────────────────────────────
  Widget _buildReturnCard(ReturnModel ret) {
    final fmt   = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final price = fmt.format(ret.total);

    const labelStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: Color(0xFF717783), letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFFE65100), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Badge RETUR + tanggal ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_return_rounded, size: 12, color: Color(0xFFE65100)),
                  SizedBox(width: 4),
                  Text('PERMINTAAN RETUR',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                          color: Color(0xFFE65100), letterSpacing: 0.6)),
                ],
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(ret.createdAt),
              style: const TextStyle(fontSize: 11, color: Color(0xFF717783)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Gambar produk + Info ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: ret.productImageUrl.isNotEmpty
                ? Image.network(ret.productImageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_outlined, color: Colors.grey, size: 26))
                : const Icon(Icons.image_outlined, color: Colors.grey, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ret.productTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Pembeli: ${ret.buyerName.isNotEmpty ? ret.buyerName : '-'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF717783))),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: labelStyle),
                  Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue)),
                ],
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),

        // ── Alasan retur ──
        if (ret.reason.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ALASAN RETUR',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: Color(0xFFBF360C), letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(ret.reason,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Thumbnail foto kondisi produk ──
        if (ret.photoUrls.isNotEmpty) ...[
          const Text('FOTO KONDISI PRODUK',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                  color: Color(0xFF717783), letterSpacing: 0.8)),
          const SizedBox(height: 6),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ret.photoUrls.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _showReturnDetailSheet(ret),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    ret.photoUrls[i], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ketuk foto untuk melihat detail',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
        ],

        // ── Tombol / Status berdasarkan status retur ──
        if (ret.status == ReturnStatus.pending)
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showReturnDetailSheet(ret),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Detail', style: TextStyle(color: Colors.black87, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleRejectReturn(ret),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Tolak', style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleApproveReturn(ret),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Setujui', style: TextStyle(fontSize: 13)),
              ),
            ),
          ])
        else if (ret.status == ReturnStatus.approved) ...[
          // ── State: kurir menolak → seller perlu assign ulang ──────────────
          if (ret.orderStatus == 'return_requested') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFE65100)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kurir menolak tugas. Tugaskan kurir lain.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleReassignReturnCourier(ret),
                icon: const Icon(Icons.person_search_rounded, size: 16),
                label: const Text('Cari & Tugaskan Kurir Lain',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          // ── State: menunggu kurir konfirmasi (return_assigned) ──────────────
          ] else if (ret.orderStatus == 'return_assigned') ...[
            _buildReturnProgressTracker(
              courierName: ret.returnCourierName,
              isWaitingCourier: true,
              isPickedUp: false,
              isCompleted: false,
            ),
          // ── State: kurir sudah terima & progress berjalan ──────────────────
          ] else ...[
            _buildReturnProgressTracker(
              courierName: ret.returnCourierName,
              isWaitingCourier: false,
              isPickedUp: ret.orderStatus == 'returnPickedUp' || ret.orderStatus == 'return_picked_up',
              isCompleted: ret.orderStatus == 'returnCompleted' || ret.orderStatus == 'return_completed',
            ),
          ],
        ] else if (ret.status == ReturnStatus.rejected) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.cancel_rounded, size: 14, color: Colors.red),
                SizedBox(width: 6),
                Text('RETUR DITOLAK',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: Colors.red, letterSpacing: 0.6)),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  // ── Return Progress Tracker ──────────────────────────────────────────────
  Widget _buildReturnProgressTracker({
    String? courierName,
    required bool isWaitingCourier, // return_assigned: menunggu konfirmasi kurir
    required bool isPickedUp,
    required bool isCompleted,
  }) {
    const activeColor   = Color(0xFF2E7D32);
    const pendingColor  = Color(0xFFF59E0B); // amber = menunggu
    const inactiveColor = Color(0xFFBDBDBD);

    final courierSubLabel = courierName != null && courierName.isNotEmpty
        ? 'Kurir: $courierName'
        : 'Menunggu kurir...';

    final steps = [
      (
        label: 'Disetujui',
        sublabel: 'Seller telah menyetujui retur',
        icon: Icons.check_circle_rounded,
        color: activeColor,
      ),
      (
        label: 'Menunggu Konfirmasi Kurir',
        sublabel: isWaitingCourier ? courierSubLabel : (isPickedUp || isCompleted ? 'Kurir mengkonfirmasi' : ''),
        icon: Icons.hourglass_top_rounded,
        color: isWaitingCourier ? pendingColor : (isPickedUp || isCompleted ? activeColor : inactiveColor),
      ),
      (
        label: 'Kurir Menjemput',
        sublabel: isPickedUp || isCompleted ? courierSubLabel : 'Menunggu penjemputan',
        icon: Icons.local_shipping_rounded,
        color: isPickedUp || isCompleted ? activeColor : inactiveColor,
      ),
      (
        label: 'Barang Tiba',
        sublabel: isCompleted ? 'Barang telah kembali ke seller' : 'Menunggu pengiriman ke seller',
        icon: Icons.inventory_2_rounded,
        color: isCompleted ? activeColor : inactiveColor,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWaitingCourier ? const Color(0xFFFFFDE7) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWaitingCourier
              ? pendingColor.withValues(alpha: 0.35)
              : activeColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWaitingCourier ? 'MENUNGGU KONFIRMASI KURIR' : 'PROGRESS RETUR',
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800,
              color: isWaitingCourier ? pendingColor : activeColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((entry) {
            final i    = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: step.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(step.icon, size: 13, color: Colors.white),
                    ),
                    if (!isLast)
                      Container(
                        width: 2, height: 24,
                        color: step.color == inactiveColor
                            ? inactiveColor.withValues(alpha: 0.3)
                            : step.color.withValues(alpha: 0.4),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: step.color,
                          ),
                        ),
                        if (step.sublabel.isNotEmpty)
                          Text(
                            step.sublabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: step.color == inactiveColor
                                  ? inactiveColor
                                  : step.color.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }


  // ── Delivery Progress Tracker (untuk order biasa setelah kurir ditugaskan) ─
  Widget _buildDeliveryProgressTracker({
    required String courierName,
    required bool isWaitingCourier,
    required bool isPickedUp,
    required bool isDelivered,
  }) {
    const activeColor   = Color(0xFF005DA7); // primaryBlue
    const pendingColor  = Color(0xFFF59E0B); // amber = menunggu konfirmasi kurir
    const inactiveColor = Color(0xFFBDBDBD);
    const doneColor     = Color(0xFF2E7D32); // hijau = selesai

    final courierLabel = courierName.isNotEmpty ? courierName : 'Kurir';

    // Tentukan warna & sublabel step "Kurir Ditugaskan"
    final courierStepColor = isWaitingCourier
        ? pendingColor
        : (isPickedUp || isDelivered ? activeColor : inactiveColor);

    final steps = [
      (
        label: 'Dikemas',
        sublabel: 'Seller sedang mengemas pesanan',
        icon: Icons.inventory_2_rounded,
        color: doneColor, // selalu aktif (sudah lewat)
      ),
      (
        label: 'Kurir Ditugaskan',
        sublabel: isWaitingCourier
            ? 'Menunggu konfirmasi: $courierLabel'
            : (isPickedUp || isDelivered
                ? '$courierLabel mengkonfirmasi'
                : 'Menunggu konfirmasi kurir'),
        icon: Icons.person_pin_circle_rounded,
        color: courierStepColor,
      ),
      (
        label: 'Dalam Perjalanan',
        sublabel: isPickedUp || isDelivered
            ? 'Dibawa oleh $courierLabel'
            : 'Menunggu kurir mengambil barang',
        icon: Icons.local_shipping_rounded,
        color: isPickedUp || isDelivered ? activeColor : inactiveColor,
      ),
      (
        label: 'Pesanan Tiba',
        sublabel: isDelivered
            ? 'Barang telah tiba di pembeli'
            : 'Menunggu pengiriman ke pembeli',
        icon: Icons.home_rounded,
        color: isDelivered ? doneColor : inactiveColor,
      ),
    ];

    // Header label
    final headerLabel = isDelivered
        ? 'PESANAN TIBA DI PEMBELI'
        : isPickedUp
            ? 'KURIR DALAM PERJALANAN'
            : isWaitingCourier
                ? 'MENUNGGU KONFIRMASI KURIR'
                : 'PROGRESS PENGIRIMAN';

    final headerColor = isDelivered
        ? doneColor
        : isPickedUp
            ? activeColor
            : isWaitingCourier
                ? pendingColor
                : activeColor;

    final bgColor = isWaitingCourier
        ? const Color(0xFFFFFDE7)
        : isPickedUp
            ? const Color(0xFFE3F2FD)
            : isDelivered
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFE3F2FD);

    final borderColor = isWaitingCourier
        ? pendingColor.withValues(alpha: 0.35)
        : isDelivered
            ? doneColor.withValues(alpha: 0.3)
            : activeColor.withValues(alpha: 0.25);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDelivered
                    ? Icons.check_circle_rounded
                    : isPickedUp
                        ? Icons.local_shipping_rounded
                        : isWaitingCourier
                            ? Icons.hourglass_top_rounded
                            : Icons.info_outline_rounded,
                size: 13,
                color: headerColor,
              ),
              const SizedBox(width: 5),
              Text(
                headerLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: headerColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((entry) {
            final i    = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: step.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(step.icon, size: 13, color: Colors.white),
                    ),
                    if (!isLast)
                      Container(
                        width: 2, height: 24,
                        color: step.color == inactiveColor
                            ? inactiveColor.withValues(alpha: 0.3)
                            : step.color.withValues(alpha: 0.4),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: step.color,
                          ),
                        ),
                        if (step.sublabel.isNotEmpty)
                          Text(
                            step.sublabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: step.color == inactiveColor
                                  ? inactiveColor
                                  : step.color.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }


  // ── Return Detail Bottom Sheet ─────────────────────────────────────────────
  void _showReturnDetailSheet(ReturnModel ret) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_return_rounded,
                        color: Color(0xFFE65100), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detail Permintaan Retur',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(ret.productTitle,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF717783)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Info dasar
              _infoRow('Pembeli', ret.buyerName.isNotEmpty ? ret.buyerName : '-'),
              const SizedBox(height: 8),
              _infoRow('Total Nilai', fmt.format(ret.total)),
              const SizedBox(height: 8),
              _infoRow('Tanggal Retur', _formatDate(ret.createdAt)),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Alasan retur
              const Text('ALASAN RETUR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: Color(0xFFBF360C), letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.2)),
                ),
                child: Text(
                  ret.reason.isNotEmpty ? ret.reason : 'Tidak ada deskripsi.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037), height: 1.5),
                ),
              ),

              // Foto kondisi produk (tampil full width satu per satu)
              if (ret.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('FOTO KONDISI PRODUK',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: Color(0xFF717783), letterSpacing: 0.8)),
                const SizedBox(height: 10),
                ...ret.photoUrls.map((url) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 180,
                              color: const Color(0xFFF5F5F5),
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: const Color(0xFFEEEEEE),
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  ),
                )),
              ],

              const SizedBox(height: 24),

              // Tombol Tolak & Setujui
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleRejectReturn(ret);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Tolak Retur',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleApproveReturn(ret);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Setujui Retur',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF717783))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
    ],
  );

  static String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Detail Pesanan Bottom Sheet (untuk tab Order) ─────────────────────────
  void _showOrderDetailSheet(BuildContext context, OrderModel order) {
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Detail Pesanan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    purchaseType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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

            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productTitle,
                      style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 3),
                  Text('Total Pembelian: ${item.quantity} ${item.unit}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF717783))),
                ],
              ),
            )),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

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

            if (order.buyerAddress.isNotEmpty) ...[
              Text(
                'Alamat: ${order.buyerAddress}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF717783), height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Lihat Penilaian Bottom Sheet ──────────────────────────────────────────
  // -- Lihat Penilaian -- fetch real-time dari koleksi reviews --
  void _showReviewSheet(BuildContext context, OrderModel order) {
    final productId = order.firstItem?.productId ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: productId.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Produk tidak diketahui.',
                      style: TextStyle(color: Colors.grey)),
                ))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _reviewsStream(productId),
                  builder: (ctx, snap) {
                    final reviews = snap.data ?? [];
                    return ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCEEFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: primaryBlue, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ulasan Pembeli',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text(order.firstItem?.productTitle ?? '',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF717783)),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (snap.connectionState == ConnectionState.waiting)
                              const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 16),

                        if (snap.hasError)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Gagal memuat ulasan. Coba lagi nanti.',
                                style: const TextStyle(color: Colors.red, fontSize: 13)),
                          )
                        else if (reviews.isEmpty && snap.connectionState != ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 40, color: Color(0xFFDDDDDD)),
                                  SizedBox(height: 12),
                                  Text('Belum ada ulasan untuk produk ini.',
                                      style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          // Summary rata-rata
                          if (reviews.isNotEmpty) ...{
                            () {
                              final avg = reviews.fold<double>(
                                  0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) / reviews.length;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCEEFF).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(avg.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryBlue)),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: List.generate(5, (i) => Icon(
                                          i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: const Color(0xFFFFC107), size: 18))),
                                        Text('\ ulasan',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF717783))),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }(),
                          },
                          // Daftar review
                          ...reviews.map((r) => _buildSellerReviewCard(r)),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  // Stream reviews for a product from Firestore
  Stream<List<Map<String, dynamic>>> _reviewsStream(String productId) {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => d.data())
          .toList();
      list.sort((a, b) {
        final ta = a['createdAt'] as Timestamp?;
        final tb = b['createdAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  Widget _buildSellerReviewCard(Map<String, dynamic> r) {
    final buyerName    = r['buyerName']    as String? ?? 'Pembeli';
    final rating       = (r['rating']      as num?)?.toInt() ?? 0;
    final reviewText   = r['reviewText']   as String? ?? '';
    final purchaseType = r['purchaseType'] as String? ?? 'standard';
    final isSample     = purchaseType.toLowerCase() == 'sample';
    final rawPhotos    = r['photoUrls']    as List<dynamic>? ?? [];
    final photoUrls    = rawPhotos.cast<String>();
    final videoUrl     = r['videoUrl']     as String?;
    final ts           = r['createdAt'];
    String dateStr = '';
    if (ts != null) {
      try {
        final dt = (ts as Timestamp).toDate();
        const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
        dateStr = dt.day.toString() + ' ' + months[dt.month - 1] + ' ' + dt.year.toString();
      } catch (_) {}
    }
    final initial = buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: avatar + nama + tanggal + bintang
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFDCEEFF),
                child: Text(initial,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryBlue)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(buyerName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF717783))),
                  ],
                ),
              ),
              Row(children: List.generate(5, (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFFFC107), size: 14))),
            ],
          ),
          const SizedBox(height: 8),
          // Badge Standard/Sample
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSample ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSample ? const Color(0xFF2E7D32) : primaryBlue,
                width: 0.8,
              ),
            ),
            child: Text(
              isSample ? 'Sample' : 'Standard',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: isSample ? const Color(0xFF2E7D32) : primaryBlue,
              ),
            ),
          ),
          if (reviewText.isNotEmpty) ...{
            const SizedBox(height: 10),
            Text(reviewText,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
          },
          // Foto
          if (photoUrls.isNotEmpty) ...{
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: photoUrls.map((url) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(url, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined, color: Colors.grey)),
                )).toList(),
              ),
            ),
          },
          // Video
          if (videoUrl != null) ...{
            const SizedBox(height: 10),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEEFF).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.play_circle_rounded, color: primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text('Video Ulasan tersedia',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue)),
                ],
              ),
            ),
          },
        ],
      ),
    );
  }

  // ── Approve & Reject Return ────────────────────────────────────────────────
  Future<void> _handleApproveReturn(ReturnModel ret) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Retur', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setujui permintaan retur dari ${ret.buyerName}?',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_shipping_rounded, size: 16, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kurir akan otomatis ditugaskan untuk menjemput barang dari buyer.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1565C0), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Catatan untuk pembeli (opsional)...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Setujui & Tugaskan Kurir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(sellerOrderRepositoryProvider);
    try {
      await repo.approveReturn(
        returnId: ret.returnId,
        orderId:  ret.orderId,
        note:     noteCtrl.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Retur disetujui! Kurir telah ditugaskan untuk menjemput barang.'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleRejectReturn(ReturnModel ret) async {
    final noteCtrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Retur', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak permintaan retur dari ${ret.buyerName}?',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Alasan penolakan retur (wajib)...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Tolak Retur'),
          ),
        ],
      ),
    );
    if (note == null || note.isEmpty) return;

    final repo = ref.read(sellerOrderRepositoryProvider);
    try {
      await repo.rejectReturn(
        returnId: ret.returnId,
        orderId:  ret.orderId,
        note:     note,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('❌ Retur ditolak.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Tugaskan Ulang Kurir (setelah kurir menolak return task) ──────────────
  Future<void> _handleReassignReturnCourier(ReturnModel ret) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cari Kurir Lain', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Sistem akan otomatis mencari dan menugaskan kurir aktif lain untuk menjemput barang retur ini.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white),
            child: const Text('Tugaskan Ulang'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(sellerOrderRepositoryProvider);
    try {
      await repo.reassignReturnCourier(
        returnId: ret.returnId,
        orderId:  ret.orderId,
        excludeCourierId: ret.returnCourierId,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🚚 Kurir baru berhasil ditugaskan untuk retur!'),
        backgroundColor: const Color(0xFFE65100),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal: ${e.toString().replaceFirst('Exception: ', '')}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Actions untuk Order biasa ──────────────────────────────────────────────
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
        content: const Text('❌ Order ditolak'),
        backgroundColor: Colors.red,
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

  // ── Empty & Loading States ─────────────────────────────────────────────────
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
          Icon(Icons.assignment_return_rounded, size: 36, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text('Tidak ada permintaan retur',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFAAAAAA))),
          SizedBox(height: 6),
          Text('Permintaan retur dari pembeli akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), height: 1.5)),
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
