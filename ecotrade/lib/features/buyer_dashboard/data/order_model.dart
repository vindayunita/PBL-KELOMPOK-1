import 'package:cloud_firestore/cloud_firestore.dart';

/// Status alur order dari buyer's perspective.
enum OrderStatus {
  pendingVerification, // menunggu verifikasi admin
  verified,            // admin terima → menunggu seller proses
  processing,          // seller terima → sedang diproses
  rejected,            // seller tolak
  shipped,             // barang dalam pengiriman
  completed,           // pesanan selesai
  cancelled,           // dibatalkan
  unknown,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingVerification: return 'Pending Admin';
      case OrderStatus.verified:           return 'Diverifikasi';
      case OrderStatus.processing:         return 'Diproses';
      case OrderStatus.rejected:           return 'Ditolak Seller';
      case OrderStatus.shipped:            return 'Dalam Pengiriman';
      case OrderStatus.completed:          return 'Selesai';
      case OrderStatus.cancelled:          return 'Dibatalkan';
      case OrderStatus.unknown:            return 'Tidak Diketahui';
    }
  }
}

OrderStatus orderStatusFromString(String? s) {
  switch (s) {
    case 'pending_verification': return OrderStatus.pendingVerification;
    case 'verified':             return OrderStatus.verified;
    case 'processing':           return OrderStatus.processing;
    case 'rejected':             return OrderStatus.rejected;
    case 'shipped':              return OrderStatus.shipped;
    case 'completed':            return OrderStatus.completed;
    case 'cancelled':            return OrderStatus.cancelled;
    default:                     return OrderStatus.unknown;
  }
}

class OrderItemSnapshot {
  const OrderItemSnapshot({
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.sellerId,
    required this.sellerName,
    this.purchaseType = 'standard',
  });

  final String productId;
  final String productTitle;
  final String productImageUrl;
  final double unitPrice;
  final int    quantity;
  final String unit;
  final String sellerId;
  final String sellerName;
  final String purchaseType;

  double get subtotal => unitPrice * quantity;

  factory OrderItemSnapshot.fromMap(Map<String, dynamic> m) =>
      OrderItemSnapshot(
        productId:       m['productId']       as String? ?? '',
        productTitle:    m['productTitle']     as String? ?? '',
        productImageUrl: m['productImageUrl']  as String? ?? '',
        unitPrice:       (m['unitPrice']  as num?)?.toDouble() ?? 0,
        quantity:        (m['quantity']   as num?)?.toInt()    ?? 1,
        unit:            m['unit']             as String? ?? 'kg',
        sellerId:        m['sellerId']         as String? ?? '',
        sellerName:      m['sellerName']       as String? ?? '',
        purchaseType:    m['purchaseType']     as String? ?? 'standard',
      );
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.buyerAddress,
    required this.paymentProofUrl,
    required this.paymentMethod,
    required this.createdAt,
    this.reviewText,
    this.rating,
    this.returnReason,
  });

  final String              id;
  final List<OrderItemSnapshot> items;
  final double              total;
  final OrderStatus         status;
  final String              buyerAddress;
  final String              paymentProofUrl;
  final String              paymentMethod;
  final DateTime            createdAt;
  final String?             reviewText;
  final int?                rating;
  final String?             returnReason;

  /// First item convenience
  OrderItemSnapshot? get firstItem => items.isNotEmpty ? items.first : null;
  String get batchCode =>
      'ETC-${id.substring(0, 5).toUpperCase()}';

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => OrderItemSnapshot.fromMap(e as Map<String, dynamic>))
        .toList();

    final ts = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (ts is Timestamp) createdAt = ts.toDate();

    return OrderModel(
      id:              doc.id,
      items:           items,
      total:           (data['total']   as num?)?.toDouble()    ?? 0,
      status:          orderStatusFromString(data['status'] as String?),
      buyerAddress:    data['buyerAddress']    as String? ?? '',
      paymentProofUrl: data['paymentProofUrl'] as String? ?? '',
      paymentMethod:   data['paymentMethod']   as String? ?? '',
      createdAt:       createdAt,
      reviewText:      data['reviewText']  as String?,
      rating:          (data['rating'] as num?)?.toInt(),
      returnReason:    data['returnReason'] as String?,
    );
  }
}
