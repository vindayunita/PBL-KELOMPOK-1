import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../user/data/user_repository.dart';
import '../domain/order_model.dart';

part 'order_repository.g.dart';

@riverpod
OrderRepository orderRepository(Ref ref) =>
    OrderRepository(ref.watch(firestoreProvider));

class OrderRepository {
  OrderRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  // ── Seller: stream orders milik seller tertentu ────────────────────────────
  Stream<List<OrderModel>> watchOrdersBySeller(String sellerId) {
    return _orders
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  // ── Kurir: stream orders yang di-assign ke kurir tertentu ─────────────────
  Stream<List<OrderModel>> watchOrdersByCourier(String courierId) {
    return _orders
        .where('courierId', isEqualTo: courierId)
        .where('status', whereIn: ['assigned', 'picked_up'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  // ── Admin: stream orders berdasarkan status ───────────────────────────────
  Stream<List<OrderModel>> watchOrdersByStatus(String status) {
    return _orders
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  // ── Seller: konfirmasi order (pending → confirmed) ────────────────────────
  Future<void> confirmOrder(String orderId) {
    return _orders.doc(orderId).update({
      'status':    OrderStatus.confirmed.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Seller: tolak order ───────────────────────────────────────────────────
  Future<void> rejectOrder(String orderId, String reason) {
    return _orders.doc(orderId).update({
      'status':          'rejected',
      'rejectionReason': reason,
      'updatedAt':       FieldValue.serverTimestamp(),
    });
  }

  // ── Seller: tugaskan kurir ke order (confirmed → assigned) ────────────────
  Future<void> assignCourier(
    String orderId, {
    required String courierId,
    required String courierName,
    required String courierPhone,
  }) {
    return _orders.doc(orderId).update({
      'status':       OrderStatus.assigned.toJson(),
      'courierId':    courierId,
      'courierName':  courierName,
      'courierPhone': courierPhone,
      'updatedAt':    FieldValue.serverTimestamp(),
    });
  }

  // ── Kurir: ambil barang di seller (assigned → picked_up) ─────────────────
  Future<void> markPickedUp(String orderId) {
    return _orders.doc(orderId).update({
      'status':    OrderStatus.pickedUp.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Kurir: selesaikan pengiriman (picked_up → delivered) ─────────────────
  Future<void> markDelivered(String orderId) {
    return _orders.doc(orderId).update({
      'status':    OrderStatus.delivered.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
