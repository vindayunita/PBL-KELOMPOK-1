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

  // ── Order masuk: semua order seller yang masih aktif ──────────────────────
  // Filter status dilakukan di sisi client agar tidak perlu composite index
  // (Firestore tidak support arrayContains + whereIn tanpa index)
  static const _incomingStatuses = {
    OrderStatus.verified,
    OrderStatus.processing,
    OrderStatus.assigned,
    OrderStatus.pickedUp,
  };

  Stream<List<OrderModel>> watchIncomingOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(OrderModel.fromFirestore)
              .where((o) => _incomingStatuses.contains(o.status))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Order selesai ─────────────────────────────────────────────────────────
  Stream<List<OrderModel>> watchCompletedOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(OrderModel.fromFirestore)
              .where((o) => o.status == OrderStatus.completed)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Return request ────────────────────────────────────────────────────────
  Stream<List<OrderModel>> watchReturnOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(OrderModel.fromFirestore)
              .where((o) => o.status == OrderStatus.returnRequested)
              .toList();
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

  // ── Seller assign kurir otomatis → assigned ──────────────────────────────
  Future<void> assignCourier(String orderId, {String? excludeCourierId}) async {
    // 1. Cari kurir yang AKTIF (isActive == true) terlebih dahulu
    final activeSnap = await _db
        .collection('courier_applications')
        .where('status',   isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .get();

    // Kecualikan kurir yang sudah menolak
    var activeDocs = excludeCourierId != null
        ? activeSnap.docs.where((d) => d.id != excludeCourierId).toList()
        : activeSnap.docs.toList();

    // 2. Fallback: jika tidak ada kurir aktif, ambil semua kurir approved
    if (activeDocs.isEmpty) {
      final allSnap = await _db
          .collection('courier_applications')
          .where('status', isEqualTo: 'approved')
          .get();
      activeDocs = excludeCourierId != null
          ? allSnap.docs.where((d) => d.id != excludeCourierId).toList()
          : allSnap.docs.toList();
    }

    if (activeDocs.isEmpty) {
      throw Exception('Tidak ada kurir tersedia saat ini.');
    }

    // 3. Pilih satu kurir secara acak
    activeDocs.shuffle();
    final courierDoc  = activeDocs.first;
    final courierId   = courierDoc.id;
    final courierName = courierDoc.data()['fullName'] as String? ?? 'Kurir';

    // 4. Update order — status 'assigned'
    await _orders.doc(orderId).update({
      'status':      'assigned',
      'courierId':   courierId,
      'courierName': courierName,
      'updatedAt':   FieldValue.serverTimestamp(),
    });
  }

  // ── Re-assign ke kurir lain (dipanggil saat kurir tolak tugas) ───────────
  Future<void> reAssignCourier(String orderId, String rejectedCourierId) {
    return assignCourier(orderId, excludeCourierId: rejectedCourierId);
  }

  // ── Seller mark selesai → completed ──────────────────────────────────────
  Future<void> completeOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status':    'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
