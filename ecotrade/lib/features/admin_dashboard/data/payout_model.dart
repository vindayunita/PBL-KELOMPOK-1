import 'package:cloud_firestore/cloud_firestore.dart';

enum PayoutStatus { pending, approved, rejected }

class PayoutModel {
  const PayoutModel({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.userName,
    required this.amount,
    required this.bankName,
    required this.bankAccountName,
    required this.bankAccountNumber,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.adminNote,
  });

  final String id;
  final String userId;
  final String userRole; // 'buyer' or 'seller'
  final String userName;
  final double amount;
  
  // Bank details
  final String bankName;
  final String bankAccountName;
  final String bankAccountNumber;

  final PayoutStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? adminNote;

  factory PayoutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    PayoutStatus parseStatus(String? s) {
      switch (s) {
        case 'approved': return PayoutStatus.approved;
        case 'rejected': return PayoutStatus.rejected;
        default: return PayoutStatus.pending;
      }
    }

    return PayoutModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userRole: data['userRole'] as String? ?? 'buyer',
      userName: data['userName'] as String? ?? 'User',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      bankName: data['bankName'] as String? ?? '',
      bankAccountName: data['bankAccountName'] as String? ?? '',
      bankAccountNumber: data['bankAccountNumber'] as String? ?? '',
      status: parseStatus(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      adminNote: data['adminNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userRole': userRole,
      'userName': userName,
      'amount': amount,
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      if (processedAt != null) 'processedAt': processedAt,
      if (adminNote != null) 'adminNote': adminNote,
    };
  }
}
