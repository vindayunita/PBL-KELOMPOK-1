import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/notifications/notification_trigger.dart';
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
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        });
  }

  // ── Kurir: stream orders yang di-assign ke kurir tertentu ─────────────────
  Stream<List<OrderModel>> watchOrdersByCourier(String courierId) {
    return _orders
        .where('courierId', isEqualTo: courierId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        });
  }

  // ── Kurir: stream tugas retur yang di-assign ke kurir tertentu ─────────────
  /// Query berdasarkan `returnCourierId` lalu filter client-side
  /// untuk status `return_assigned`, `return_approved`, dan `return_picked_up`.
  Stream<List<OrderModel>> watchReturnTasksByCourier(String courierId) {
    return _orders
        .where('returnCourierId', isEqualTo: courierId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(OrderModel.fromFirestore)
              .where((o) =>
                  o.status == OrderStatus.returnAssigned ||
                  o.status == OrderStatus.returnApproved ||
                  o.status == OrderStatus.returnPickedUp)
              .toList();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        });
  }

  // ── Kurir: stream tugas retur SELESAI yang di-assign ke kurir tertentu ────
  Stream<List<OrderModel>> watchHistoryReturnTasksByCourier(String courierId) {
    return _orders
        .where('returnCourierId', isEqualTo: courierId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(OrderModel.fromFirestore)
              .where((o) => o.status == OrderStatus.returnCompleted)
              .toList();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        });
  }

  // ── Admin: stream orders berdasarkan status ───────────────────────────────
  Stream<List<OrderModel>> watchOrdersByStatus(String status) {
    return _orders
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        });
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
  Future<void> markPickedUp(String orderId) async {
    // Baca data order untuk notifikasi sebelum update
    final snap   = await _orders.doc(orderId).get();
    final data   = snap.data();
    final buyerId      = data?['buyerId']     as String? ?? '';
    final courierName  = data?['courierName'] as String? ?? 'Kurir';

    await _orders.doc(orderId).update({
      'status':    OrderStatus.pickedUp.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Notifikasi ke buyer: pesanan sedang dalam perjalanan
    unawaited(NotificationTrigger.orderPickedUp(
      buyerId:     buyerId,
      orderId:     orderId,
      courierName: courierName,
    ));
  }

  // ── Kurir: selesaikan pengiriman (picked_up → delivered) ─────────────────
  Future<void> markDelivered(String orderId) async {
    // Baca buyerId sebelum update untuk notifikasi
    final snap   = await _orders.doc(orderId).get();
    final buyerId = snap.data()?['buyerId'] as String? ?? '';

    await _orders.doc(orderId).update({
      'status':    OrderStatus.delivered.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Notifikasi ke buyer: pesanan sudah tiba
    unawaited(NotificationTrigger.orderDelivered(
      buyerId: buyerId,
      orderId: orderId,
    ));
  }

  // ── Kurir: ambil barang retur dari buyer (return_approved → return_picked_up) ──
  Future<void> markReturnPickedUp(String orderId) async {
    final orderRef = _orders.doc(orderId);
    final returnsSnap = await _db
        .collection('returns')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    final batch = _db.batch();
    batch.update(orderRef, {
      'status':    'return_picked_up',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (returnsSnap.docs.isNotEmpty) {
      batch.update(returnsSnap.docs.first.reference, {
        'orderStatus': 'return_picked_up',
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ── Kurir: terima tugas retur (return_assigned → return_approved) ─────────
  /// Juga menyinkronkan koleksi `returns` agar seller dashboard ikut update.
  Future<void> acceptReturn(String orderId) async {
    final batch = _db.batch();

    // Update orders
    batch.update(_orders.doc(orderId), {
      'status':    'return_approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Cari dokumen returns yang terkait dengan orderId ini lalu sync
    final returnsSnap = await _db
        .collection('returns')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    if (returnsSnap.docs.isNotEmpty) {
      batch.update(returnsSnap.docs.first.reference, {
        'orderStatus': 'return_approved',
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ── Kurir: tolak tugas retur (return_assigned → return_requested) ─────────
  /// Menghapus penugasan kurir sehingga seller bisa assign ulang.
  /// Juga menyinkronkan koleksi `returns` agar seller tahu kurir menolak.
  Future<void> rejectReturnTask(String orderId) async {
    final batch = _db.batch();

    // Update orders — hapus info kurir, kembali ke return_requested
    batch.update(_orders.doc(orderId), {
      'status':            'return_requested',
      'returnCourierId':   FieldValue.delete(),
      'returnCourierName': FieldValue.delete(),
      'updatedAt':         FieldValue.serverTimestamp(),
    });

    // Sync ke returns — pertahankan status='approved' (seller sudah setuju)
    // tapi reset orderStatus + courier agar seller bisa assign ulang
    final returnsSnap = await _db
        .collection('returns')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    if (returnsSnap.docs.isNotEmpty) {
      batch.update(returnsSnap.docs.first.reference, {
        'orderStatus':       'return_requested',
        'returnCourierId':   FieldValue.delete(),
        'returnCourierName': FieldValue.delete(),
        'updatedAt':         FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ── Kurir: serahkan barang ke seller (return_picked_up → return_completed) ──
  Future<void> markReturnDelivered(String orderId) async {
    final orderRef = _orders.doc(orderId);
    final returnsSnap = await _db
        .collection('returns')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    
    await _db.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw Exception('Order tidak ditemukan');
      
      final data = orderSnap.data()!;
      final buyerId = data['buyerId'] as String?;
      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      
      // Update status order
      tx.update(orderRef, {
        'status':    'return_completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (returnsSnap.docs.isNotEmpty) {
        tx.update(returnsSnap.docs.first.reference, {
          'orderStatus': 'return_completed',
          'updatedAt':   FieldValue.serverTimestamp(),
        });
      }
      
      // Tambahkan saldo refund ke pembeli
      if (buyerId != null && buyerId.isNotEmpty && total > 0) {
        final userRef = _db.collection('users').doc(buyerId);
        tx.set(userRef, {
          'refundBalance': FieldValue.increment(total),
        }, SetOptions(merge: true));
        
        unawaited(NotificationTrigger.refundBalanceAdded(
          buyerId: buyerId,
          amount: total,
        ));
      }
    });

    // 🔔 Notifikasi ke seller: barang retur sudah kembali
    // Ambil sellerId dari order (sellerIds field)
    final orderSnap2 = await _orders.doc(orderId).get();
    final sellerIds  = (orderSnap2.data()?['sellerIds'] as List<dynamic>? ?? []).cast<String>();
    for (final sid in sellerIds) {
      unawaited(NotificationTrigger.returnCompleted(
        sellerId: sid,
        orderId:  orderId,
      ));
    }
  }
}
