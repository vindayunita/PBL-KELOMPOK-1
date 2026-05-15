import 'package:cloud_firestore/cloud_firestore.dart';

// Status flow: pending → confirmed → assigned → picked_up → delivered
enum OrderStatus {
  pending,
  confirmed,
  assigned,
  pickedUp,
  delivered;

  static OrderStatus fromString(String s) {
    switch (s) {
      case 'confirmed':  return OrderStatus.confirmed;
      case 'assigned':   return OrderStatus.assigned;
      case 'picked_up':  return OrderStatus.pickedUp;
      case 'delivered':  return OrderStatus.delivered;
      default:           return OrderStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case OrderStatus.confirmed:  return 'confirmed';
      case OrderStatus.assigned:   return 'assigned';
      case OrderStatus.pickedUp:   return 'picked_up';
      case OrderStatus.delivered:  return 'delivered';
      case OrderStatus.pending:    return 'pending';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:    return 'Menunggu Konfirmasi';
      case OrderStatus.confirmed:  return 'Dikonfirmasi Seller';
      case OrderStatus.assigned:   return 'Kurir Ditugaskan';
      case OrderStatus.pickedUp:   return 'Dalam Pengiriman';
      case OrderStatus.delivered:  return 'Terkirim';
    }
  }
}

class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerAddress,
    required this.sellerId,
    required this.sellerName,
    required this.sellerCity,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
    required this.status,
    this.courierId,
    this.courierName,
    this.courierPhone,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  final String orderId;
  final String buyerId;
  final String buyerName;
  final String buyerAddress;
  final String sellerId;
  final String sellerName;
  final String sellerCity;
  final String productId;
  final String productName;
  final int quantity;
  final String unit;
  final double totalPrice;
  final OrderStatus status;
  final String? courierId;
  final String? courierName;
  final String? courierPhone;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending   => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isAssigned  => status == OrderStatus.assigned;
  bool get isPickedUp  => status == OrderStatus.pickedUp;
  bool get isDelivered => status == OrderStatus.delivered;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId:         doc.id,
      buyerId:         data['buyerId']       as String? ?? '',
      buyerName:       data['buyerName']     as String? ?? 'Pembeli',
      buyerAddress:    data['buyerAddress']  as String? ?? '',
      sellerId:        data['sellerId']      as String? ?? '',
      sellerName:      data['sellerName']    as String? ?? 'Seller',
      sellerCity:      data['sellerCity']    as String? ?? '',
      productId:       data['productId']     as String? ?? '',
      productName:     data['productName']   as String? ?? '',
      quantity:        (data['quantity']     as num?)?.toInt() ?? 1,
      unit:            data['unit']          as String? ?? 'kg',
      totalPrice:      (data['totalPrice']   as num?)?.toDouble() ?? 0,
      status:          OrderStatus.fromString(data['status'] as String? ?? 'pending'),
      courierId:       data['courierId']     as String?,
      courierName:     data['courierName']   as String?,
      courierPhone:    data['courierPhone']  as String?,
      rejectionReason: data['rejectionReason'] as String?,
      createdAt:       (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt:       (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'buyerId':       buyerId,
    'buyerName':     buyerName,
    'buyerAddress':  buyerAddress,
    'sellerId':      sellerId,
    'sellerName':    sellerName,
    'sellerCity':    sellerCity,
    'productId':     productId,
    'productName':   productName,
    'quantity':      quantity,
    'unit':          unit,
    'totalPrice':    totalPrice,
    'status':        status.toJson(),
    if (courierId     != null) 'courierId':       courierId,
    if (courierName   != null) 'courierName':     courierName,
    if (courierPhone  != null) 'courierPhone':    courierPhone,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };
}
