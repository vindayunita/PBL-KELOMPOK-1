import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  PaymentModel({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.total,
    required this.paymentProofUrl,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.verifiedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  final String id;
  final String orderId;
  final String buyerId;
  final String buyerName;
  final double total;
  final String paymentProofUrl;
  final String status; // 'pending', 'verified', 'rejected'
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      orderId: data['orderId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      paymentProofUrl: data['paymentProofUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      paymentMethod: data['paymentMethod'] as String? ?? 'bank_transfer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'total': total,
      'paymentProofUrl': paymentProofUrl,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }
}
