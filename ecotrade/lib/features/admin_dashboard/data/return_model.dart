import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk dokumen di koleksi `returns`.
/// Dibuat oleh buyer melalui `requestReturnWithPhotos()`.
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
    this.adminNote,
    this.refundedAt,
  });

  final String       returnId;
  final String       orderId;
  final String       buyerId;
  final String       buyerName;
  final List<String> sellerIds;
  final String       productTitle;
  final String       productImageUrl;
  final double       total;
  final String       reason;
  final List<String> photoUrls;

  /// Status: 'pending' | 'approved' | 'rejected'
  final String       status;
  final DateTime     createdAt;
  final String?      sellerNote;
  final String?      adminNote;
  final DateTime?    refundedAt;

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory ReturnModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['createdAt'];
    final refundTs = d['refundedAt'];
    return ReturnModel(
      returnId:        d['returnId']        as String?  ?? doc.id,
      orderId:         d['orderId']         as String?  ?? '',
      buyerId:         d['buyerId']         as String?  ?? '',
      buyerName:       d['buyerName']       as String?  ?? '',
      sellerIds:       ((d['sellerIds'] as List<dynamic>?) ?? []).cast<String>(),
      productTitle:    d['productTitle']    as String?  ?? '',
      productImageUrl: d['productImageUrl'] as String?  ?? '',
      total:           (d['total']  as num?)?.toDouble() ?? 0,
      reason:          d['reason']          as String?  ?? '',
      photoUrls:       ((d['photoUrls'] as List<dynamic>?) ?? []).cast<String>(),
      status:          d['status']          as String?  ?? 'pending',
      createdAt:       ts  is Timestamp ? ts.toDate()      : DateTime.now(),
      sellerNote:      d['sellerNote']  as String?,
      adminNote:       d['adminNote']   as String?,
      refundedAt:      refundTs is Timestamp ? refundTs.toDate() : null,
    );
  }
}
