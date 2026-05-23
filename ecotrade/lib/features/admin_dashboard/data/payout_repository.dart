import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'payout_model.dart';

part 'payout_repository.g.dart';

@riverpod
PayoutRepository payoutRepository(Ref ref) {
  return PayoutRepository(FirebaseFirestore.instance);
}

class PayoutRepository {
  PayoutRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _payouts =>
      _db.collection('payouts');

  // ── Stream Payouts by Role (Admin view) ──
  Stream<List<PayoutModel>> watchPayoutsByRole(String userRole) {
    return _payouts
        .where('userRole', isEqualTo: userRole)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(PayoutModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Stream Payouts by User (User view) ──
  Stream<List<PayoutModel>> watchPayoutsByUser(String userId) {
    return _payouts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(PayoutModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Buyer: Request Refund Withdrawal ──
  Future<void> requestRefundPayout({
    required String userId,
    required String userName,
    required double amount,
    required String bankName,
    required String bankAccountName,
    required String bankAccountNumber,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    final payoutRef = _payouts.doc();

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw Exception('User tidak ditemukan');

      final currentBalance = (userSnap.data()?['refundBalance'] as num?)?.toDouble() ?? 0.0;
      if (currentBalance < amount || currentBalance <= 0) {
        throw Exception('Saldo tidak mencukupi');
      }

      // Kurangi saldo refund
      tx.update(userRef, {
        'refundBalance': FieldValue.increment(-amount),
      });

      // Buat request payout
      final payoutData = PayoutModel(
        id: payoutRef.id,
        userId: userId,
        userRole: 'buyer',
        userName: userName,
        amount: amount,
        bankName: bankName,
        bankAccountName: bankAccountName,
        bankAccountNumber: bankAccountNumber,
        status: PayoutStatus.pending,
        createdAt: DateTime.now(), // akan dioverride oleh serverTimestamp di toMap()
      ).toMap();

      tx.set(payoutRef, payoutData);
    });
  }

  // ── Admin: Approve Payout ──
  Future<void> approvePayout(String payoutId, {String? note}) async {
    await _payouts.doc(payoutId).update({
      'status': PayoutStatus.approved.name,
      'processedAt': FieldValue.serverTimestamp(),
      if (note != null) 'adminNote': note,
    });
  }

  // ── Admin: Reject Payout (Kembalikan Saldo) ──
  Future<void> rejectPayout(String payoutId, String userId, double amount, {String? note}) async {
    final payoutRef = _payouts.doc(payoutId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      // Update payout status
      tx.update(payoutRef, {
        'status': PayoutStatus.rejected.name,
        'processedAt': FieldValue.serverTimestamp(),
        if (note != null) 'adminNote': note,
      });

      // Kembalikan saldo ke user
      tx.set(userRef, {
        'refundBalance': FieldValue.increment(amount),
      }, SetOptions(merge: true));
    });
  }
}
