import 'package:cloud_firestore/cloud_firestore.dart';

/// Status permintaan retur dari perspektif buyer maupun seller.
enum ReturnStatus {
  pending,   // buyer sudah ajukan, menunggu keputusan seller
  approved,  // seller setujui retur
  rejected,  // seller tolak retur
}

extension ReturnStatusX on ReturnStatus {
  String get label {
    switch (this) {
      case ReturnStatus.pending:  return 'Menunggu Konfirmasi';
      case ReturnStatus.approved: return 'Disetujui';
      case ReturnStatus.rejected: return 'Ditolak';
    }
  }

  String get value {
    switch (this) {
      case ReturnStatus.pending:  return 'pending';
      case ReturnStatus.approved: return 'approved';
      case ReturnStatus.rejected: return 'rejected';
    }
  }
}

ReturnStatus returnStatusFromString(String? s) {
  switch (s) {
    case 'approved': return ReturnStatus.approved;
    case 'rejected': return ReturnStatus.rejected;
    default:         return ReturnStatus.pending;
  }
}

/// Model untuk dokumen di koleksi `returns`.
class ReturnModel {
  const ReturnModel({
    required this.returnId,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerIds,
    required this.productTitle,
    required this.productImageUrl,
    required this.total,
    required this.reason,
    required this.photoUrls,
    required this.status,
    required this.createdAt,
    this.sellerNote,
    this.returnCourierId,
    this.returnCourierName,
    this.orderStatus,
  });

  final String         returnId;
  final String         orderId;
  final String         buyerId;
  final String         buyerName;
  final List<String>   sellerIds;
  final String         productTitle;
  final String         productImageUrl;
  final double         total;
  final String         reason;
  /// URL foto kondisi produk yang di-upload buyer (maks 3).
  final List<String>   photoUrls;
  final ReturnStatus   status;
  final DateTime       createdAt;
  /// Catatan seller saat approve / reject.
  final String?        sellerNote;
  /// ID kurir yang ditugaskan untuk menjemput barang retur.
  final String?        returnCourierId;
  /// Nama kurir retur.
  final String?        returnCourierName;
  /// Status dari order document ('return_requested', 'return_approved', 'return_picked_up', 'return_completed')
  final String?        orderStatus;

  factory ReturnModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();

    final rawPhotos  = data['photoUrls']  as List<dynamic>? ?? [];
    final rawSellers = data['sellerIds']  as List<dynamic>? ?? [];

    return ReturnModel(
      returnId:        doc.id,
      orderId:         data['orderId']         as String? ?? '',
      buyerId:         data['buyerId']         as String? ?? '',
      buyerName:       data['buyerName']       as String? ?? '',
      sellerIds:       rawSellers.map((e) => e as String).toList(),
      productTitle:    data['productTitle']    as String? ?? '',
      productImageUrl: data['productImageUrl'] as String? ?? '',
      total:           (data['total']          as num?)?.toDouble() ?? 0,
      reason:          data['reason']          as String? ?? '',
      photoUrls:       rawPhotos.map((e) => e as String).toList(),
      status:          returnStatusFromString(data['status'] as String?),
      createdAt:       createdAt,
      sellerNote:      data['sellerNote']      as String?,
      returnCourierId:   data['returnCourierId']   as String?,
      returnCourierName: data['returnCourierName'] as String?,
      orderStatus:       data['orderStatus']       as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'returnId':        returnId,
    'orderId':         orderId,
    'buyerId':         buyerId,
    'buyerName':       buyerName,
    'sellerIds':       sellerIds,
    'productTitle':    productTitle,
    'productImageUrl': productImageUrl,
    'total':           total,
    'reason':          reason,
    'photoUrls':       photoUrls,
    'status':          status.value,
    'createdAt':       FieldValue.serverTimestamp(),
    'updatedAt':       FieldValue.serverTimestamp(),
    if (returnCourierId != null)   'returnCourierId':   returnCourierId,
    if (returnCourierName != null) 'returnCourierName': returnCourierName,
    if (orderStatus != null)       'orderStatus':       orderStatus,
  };
}
