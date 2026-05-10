import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/buyer_dashboard/data/order_model.dart';

part 'seller_order_repository.g.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

@riverpod
SellerOrderRepository sellerOrderRepository(Ref ref) {
  return SellerOrderRepository(
    FirebaseFirestore.instance,
  );
}

/// Stream order "masuk" untuk seller yang sedang login.
/// Menampilkan order yang sudah diverifikasi admin (status = 'verified')
/// dan sedang diproses (status = 'processing').
@riverpod
Stream<List<OrderModel>> sellerIncomingOrders(Ref ref) {
  final repo = ref.watch(sellerOrderRepositoryProvider);
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return repo.watchIncomingOrders(user.uid);
  });
}

/// Stream order yang sudah selesai (completed) milik seller ini.
@riverpod
Stream<List<OrderModel>> sellerCompletedOrders(Ref ref) {
  final repo = ref.watch(sellerOrderRepositoryProvider);
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return repo.watchCompletedOrders(user.uid);
  });
}

/// Stream return request untuk seller ini.
@riverpod
Stream<List<OrderModel>> sellerReturnOrders(Ref ref) {
  final repo = ref.watch(sellerOrderRepositoryProvider);
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return repo.watchReturnOrders(user.uid);
  });
}

// ── Repository ────────────────────────────────────────────────────────────────
class SellerOrderRepository {
  SellerOrderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  // ── Order masuk: verified (belum diproses seller) ─────────────────────────
  Stream<List<OrderModel>> watchIncomingOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .where('status', whereIn: ['verified', 'processing'])
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Order selesai ─────────────────────────────────────────────────────────
  Stream<List<OrderModel>> watchCompletedOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Return request ────────────────────────────────────────────────────────
  Stream<List<OrderModel>> watchReturnOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .where('status', isEqualTo: 'return_requested')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Seller terima order → processing ─────────────────────────────────────
  Future<void> acceptOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status':    'processing',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Seller tolak order → rejected ────────────────────────────────────────
  Future<void> rejectOrder(String orderId, String reason) async {
    await _orders.doc(orderId).update({
      'status':          'rejected',
      'rejectionReason': reason,
      'updatedAt':       FieldValue.serverTimestamp(),
    });
  }

  // ── Seller mark selesai → completed ──────────────────────────────────────
  Future<void> completeOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status':    'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
