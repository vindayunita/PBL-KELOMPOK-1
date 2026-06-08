import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_trigger.dart';
import 'return_model.dart';

part 'admin_return_repository.g.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

@riverpod
AdminReturnRepository adminReturnRepository(Ref ref) {
  return AdminReturnRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}

/// Stream semua return requests, difilter berdasarkan status (null = semua).
@riverpod
Stream<List<ReturnModel>> allReturnRequestsStream(Ref ref, {String? status}) {
  return ref.watch(adminReturnRepositoryProvider).watchReturns(status: status);
}

// ── Repository ────────────────────────────────────────────────────────────────

class AdminReturnRepository {
  AdminReturnRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth     _auth;

  CollectionReference<Map<String, dynamic>> get _returns =>
      _db.collection('returns');

  // ── Stream returns dengan optional status filter ───────────────────────────
  Stream<List<ReturnModel>> watchReturns({String? status}) {
    Query<Map<String, dynamic>> q = _returns;
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map((snap) {
      final list = snap.docs.map(ReturnModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Admin: approve refund → tambah saldo buyer & update status ─────────────
  Future<void> approveRefund(ReturnModel returnItem) async {
    final batch = _db.batch();

    // 1. Update dokumen return
    batch.update(_returns.doc(returnItem.returnId), {
      'status':       'approved',
      'adminNote':    'Disetujui oleh admin ${_auth.currentUser?.email ?? ''}',
      'refundedAt':   FieldValue.serverTimestamp(),
      'updatedAt':    FieldValue.serverTimestamp(),
    });

    // 2. Tambah saldo refund ke buyer
    batch.update(_db.collection('users').doc(returnItem.buyerId), {
      'refundBalance': FieldValue.increment(returnItem.total),
      'updatedAt':     FieldValue.serverTimestamp(),
    });

    // 3. Update status order terkait
    if (returnItem.orderId.isNotEmpty) {
      batch.update(_db.collection('orders').doc(returnItem.orderId), {
        'status':    'return_approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // 4. Notifikasi ke buyer: dana masuk
    unawaited(NotificationTrigger.refundBalanceAdded(
      buyerId: returnItem.buyerId,
      amount:  returnItem.total,
    ));
  }

  // ── Admin: reject refund ───────────────────────────────────────────────────
  Future<void> rejectRefund(ReturnModel returnItem, String reason) async {
    final admin = _auth.currentUser;
    final batch = _db.batch();

    // 1. Update dokumen return
    batch.update(_returns.doc(returnItem.returnId), {
      'status':    'rejected',
      'adminNote': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Update status order kembali ke sebelumnya (misal 'completed')
    if (returnItem.orderId.isNotEmpty) {
      batch.update(_db.collection('orders').doc(returnItem.orderId), {
        'status':    'return_rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // 3. Notifikasi ke buyer: retur ditolak
    unawaited(NotificationTrigger.returnRejected(
      buyerId: returnItem.buyerId,
      orderId: returnItem.orderId,
      reason:  reason,
    ));
  }
}
