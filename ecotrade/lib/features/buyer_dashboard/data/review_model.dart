import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk review produk yang disimpan di koleksi `reviews` Firestore.
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.reviewText,
    required this.photoUrls,
    required this.createdAt,
    this.videoUrl,
    this.purchaseType = 'standard',
  });

  final String          id;
  final String          productId;
  final String          orderId;
  final String          buyerId;
  final String          buyerName;
  final int             rating;        // 1-5
  final String          reviewText;
  final List<String>    photoUrls;     // maks 5 foto
  final String?         videoUrl;      // maks 1 video (nullable)
  final DateTime        createdAt;
  final String          purchaseType;  // 'standard' | 'sample'

  /// Inisial nama buyer untuk avatar
  String get buyerInitial =>
      buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?';

  /// Label tipe pembelian
  bool get isSample => purchaseType.toLowerCase() == 'sample';

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final ts = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (ts is Timestamp) createdAt = ts.toDate();

    final rawPhotos = data['photoUrls'] as List<dynamic>? ?? [];

    return ReviewModel(
      id:           doc.id,
      productId:    data['productId']    as String? ?? '',
      orderId:      data['orderId']      as String? ?? '',
      buyerId:      data['buyerId']      as String? ?? '',
      buyerName:    data['buyerName']    as String? ?? 'Pembeli',
      rating:       (data['rating']      as num?)?.toInt() ?? 5,
      reviewText:   data['reviewText']   as String? ?? '',
      photoUrls:    rawPhotos.map((e) => e as String).toList(),
      videoUrl:     data['videoUrl']     as String?,
      createdAt:    createdAt,
      purchaseType: data['purchaseType'] as String? ?? 'standard',
    );
  }
}
