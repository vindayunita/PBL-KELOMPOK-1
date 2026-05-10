import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'order_model.dart';

part 'admin_order_repository.g.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
@riverpod
AdminOrderRepository adminOrderRepository(Ref ref) {
  return AdminOrderRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}

/// Stream semua orders untuk admin (dengan filter status opsional).
@riverpod
Stream<List<OrderModel>> allOrdersStream(Ref ref, {String? status}) {
  final repo = ref.watch(adminOrderRepositoryProvider);
  return repo.watchAllOrders(status: status);
}

/// Stream order yang sudah diproses admin:
/// mencakup verified, processing, dan completed.
@riverpod
Stream<List<OrderModel>> verifiedGroupOrdersStream(Ref ref) {
  final repo = ref.watch(adminOrderRepositoryProvider);
  return repo.watchVerifiedGroupOrders();
}

// ── Repository ───────────────────────────────────────────────────────────────
class AdminOrderRepository {
  AdminOrderRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  // ── Stream semua orders (opsional: filter by status tunggal) ─────────────────
  Stream<List<OrderModel>> watchAllOrders({String? status}) {
    Query<Map<String, dynamic>> q = _orders;
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((snap) {
      final list = snap.docs.map(OrderModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Stream order terverifikasi (verified + processing + completed) ──────────
  Stream<List<OrderModel>> watchVerifiedGroupOrders() {
    return _orders
        .where('status', whereIn: ['verified', 'processing', 'completed'])
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Verifikasi pembayaran → status: 'verified' + kurangi stok ──────────────
  Future<void> verifyPayment(String orderId) async {
    final admin = _auth.currentUser;

    // 1. Baca order untuk mendapatkan items
    final orderSnap = await _orders.doc(orderId).get();
    if (!orderSnap.exists) throw Exception('Order $orderId tidak ditemukan');

    final data    = orderSnap.data()!;
    final rawItems = data['items'] as List<dynamic>? ?? [];

    // 2. Batch write: update status + kurangi stok tiap produk
    final batch = _db.batch();

    // Update order status
    batch.update(_orders.doc(orderId), {
      'status':          'verified',
      'verifiedAt':      FieldValue.serverTimestamp(),
      'verifiedBy':      admin?.uid   ?? '',
      'verifiedByEmail': admin?.email ?? '',
      'updatedAt':       FieldValue.serverTimestamp(),
    });

    // Kurangi stok setiap produk
    for (final raw in rawItems) {
      final item     = raw as Map<String, dynamic>;
      final productId = item['productId'] as String?;
      final quantity  = (item['quantity'] as num?)?.toInt() ?? 0;
      if (productId == null || productId.isEmpty || quantity <= 0) continue;

      final productRef = _db.collection('products').doc(productId);
      batch.update(productRef, {
        'stock':     FieldValue.increment(-quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ── Tolak pembayaran → status: 'rejected' ────────────────────────────────
  Future<void> rejectPayment(String orderId, String reason) async {
    final admin = _auth.currentUser;
    await _orders.doc(orderId).update({
      'status':          'rejected',
      'rejectionReason': reason,
      'rejectedAt':      FieldValue.serverTimestamp(),
      'rejectedBy':      admin?.uid ?? '',
      'updatedAt':       FieldValue.serverTimestamp(),
    });
  }
}
