import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'payment_model.dart';

part 'payment_repository.g.dart';

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepository(FirebaseFirestore.instance);
}

class PaymentRepository {
  PaymentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection('payments');

  // ── Create payment record when order is placed ─────────────────────────────
  Future<void> createPayment({
    required String orderId,
    required String buyerId,
    required String buyerName,
    required double total,
    required String paymentProofUrl,
    required String paymentMethod,
  }) async {
    final ref = _payments.doc(); // Use auto-generated ID or use orderId?
    // Using auto-generated ID so one order can theoretically have multiple payment attempts,
    // though currently it's 1:1.
    await ref.set({
      'paymentId': ref.id,
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'total': total,
      'paymentProofUrl': paymentProofUrl,
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Update payment status ──────────────────────────────────────────────────
  Future<void> updatePaymentStatus(String orderId, String status, {String? reason}) async {
    // Find payment(s) by orderId and update status
    final query = await _payments.where('orderId', isEqualTo: orderId).get();
    if (query.docs.isEmpty) return; // Ignore if not found

    final batch = _db.batch();
    for (final doc in query.docs) {
      final data = {
        'status': status,
        if (status == 'verified') 'verifiedAt': FieldValue.serverTimestamp(),
        if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
        if (status == 'rejected' && reason != null) 'rejectionReason': reason,
      };
      batch.update(doc.reference, data);
    }
    await batch.commit();
  }

  // ── Stream all payments for admin ──────────────────────────────────────────
  Stream<List<PaymentModel>> watchAllPayments({String? status}) {
    Query<Map<String, dynamic>> q = _payments;
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((snap) {
      final list = snap.docs.map(PaymentModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
