import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/buyer_dashboard/data/order_model.dart';
import '../../../../features/buyer_dashboard/data/return_model.dart';

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

/// Stream return request untuk seller ini (dari koleksi `returns` + legacy `orders`).
@riverpod
Stream<List<ReturnModel>> sellerReturnRequests(Ref ref) {
  final repo = ref.watch(sellerOrderRepositoryProvider);
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return repo.watchAllReturnRequests(user.uid);
  });
}

/// [DEPRECATED] Gunakan sellerReturnRequestsProvider.
/// Tetap dipertahankan agar provider lama tidak error.
@riverpod
Stream<List<OrderModel>> sellerReturnOrders(Ref ref) {
  final repo = ref.watch(sellerOrderRepositoryProvider);
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return repo.watchReturnOrders(user.uid);
  });
}

/// Provider total pendapatan seller — hanya dari pesanan berstatus `completed`.
/// Otomatis diperbarui setiap kali buyer mengonfirmasi penerimaan barang.
final sellerTotalRevenueProvider = Provider<double>((ref) {
  final completedAsync = ref.watch(sellerCompletedOrdersProvider);
  final completed = completedAsync.value ?? [];
  return completed
      .where((o) => o.status == OrderStatus.completed)
      .fold(0.0, (sum, o) => sum + o.total);
});

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

  // ── Order selesai (delivered = kurir sudah antar, completed = buyer konfirmasi) ────
  Stream<List<OrderModel>> watchCompletedOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(OrderModel.fromFirestore)
              .where((o) =>
                  o.status == OrderStatus.completed ||
                  o.status == OrderStatus.delivered)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Return requests gabungan: koleksi `returns` + legacy `orders` ──────────
  /// Menggabungkan dua sumber data:
  /// 1. Koleksi `returns` (flow baru dengan foto)
  /// 2. Koleksi `orders` yang statusnya `return_requested` (data lama)
  Stream<List<ReturnModel>> watchAllReturnRequests(String sellerId) {
    var newList    = <ReturnModel>[];
    var legacyList = <ReturnModel>[];
    final controller = StreamController<List<ReturnModel>>();

    void emit() {
      if (controller.isClosed) return;
      // Deduplikasi berdasarkan orderId agar tidak double jika
      // sebuah order sudah punya dokumen di `returns` DAN masih return_requested
      final seen  = <String>{};
      final merged = <ReturnModel>[];
      for (final r in [...newList, ...legacyList]) {
        if (seen.add(r.orderId)) merged.add(r);
      }
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(merged);
    }

    // Stream 1: koleksi `returns` (filter pending client-side)
    final newSub = watchReturnRequests(sellerId).listen(
      (list) { newList = list; emit(); },
      onError: (e) { if (!controller.isClosed) controller.addError(e); },
    );

    // Stream 2: orders lama dengan status return_requested
    final legacySub = watchLegacyReturnOrders(sellerId).listen(
      (list) { legacyList = list; emit(); },
      onError: (e) { if (!controller.isClosed) controller.addError(e); },
    );

    // Ketika listener cancel, bersihkan semua subscription
    controller.onCancel = () {
      newSub.cancel();
      legacySub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // ── Koleksi `returns` — semua status (pending/approved/rejected) ────────────
  Stream<List<ReturnModel>> watchReturnRequests(String sellerId) {
    return _db
        .collection('returns')
        .where('sellerIds', arrayContains: sellerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(ReturnModel.fromFirestore)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Legacy stream dari orders (untuk watchAllReturnRequests) ──────────────
  Stream<List<ReturnModel>> watchLegacyReturnOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map(OrderModel.fromFirestore)
              .where((o) =>
                  o.status == OrderStatus.returnRequested ||
                  o.status == OrderStatus.returnApproved ||
                  o.status == OrderStatus.returnPickedUp ||
                  o.status == OrderStatus.returnCompleted)
              .map((order) {
                final firstItem = order.firstItem;
                
                ReturnStatus mappedStatus = ReturnStatus.pending;
                if (order.status == OrderStatus.returnApproved ||
                    order.status == OrderStatus.returnPickedUp ||
                    order.status == OrderStatus.returnCompleted) {
                  mappedStatus = ReturnStatus.approved;
                }
                
                return ReturnModel(
                  returnId:        order.id,
                  orderId:         order.id,
                  buyerId:         '', // OrderModel tidak punya buyerId field
                  buyerName:       order.displayBuyerName,
                  sellerIds:       order.sellerIds,
                  productTitle:    firstItem?.productTitle ?? '',
                  productImageUrl: firstItem?.productImageUrl ?? '',
                  total:           order.total,
                  reason:          order.returnReason ?? '',
                  photoUrls:       const [],
                  status:          mappedStatus,
                  createdAt:       order.createdAt,
                  sellerNote:      null,
                  orderStatus:     order.status.name, // e.g., 'returnApproved'
                  returnCourierId: order.returnCourierId,
                  returnCourierName: order.returnCourierName,
                );
              })
              .toList();
        });
  }

  // ── Return orders dari koleksi `orders` (legacy, dipertahankan) ───────────
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

  // ── Seller setujui return + otomatis tugaskan kurir ───────────────────────
  /// Menyetujui retur dan langsung menugaskan kurir aktif untuk menjemput
  /// barang dari buyer dan mengembalikannya ke seller.
  Future<void> approveReturn({
    required String returnId,
    required String orderId,
    String note = '',
  }) async {
    // Ambil orderSnap untuk mendapatkan sellerIds dan kota
    final orderSnap = await _orders.doc(orderId).get();
    final sellerIds = orderSnap.data()?['sellerIds'] as List<dynamic>? ?? [];

    String targetCity = 'Malang';
    if (sellerIds.isNotEmpty) {
      final sellerDoc = await _db.collection('users').doc(sellerIds.first).get();
      if (sellerDoc.exists) {
        final addresses = sellerDoc.data()?['addresses'] as List<dynamic>? ?? [];
        if (addresses.isNotEmpty) {
          targetCity = addresses.first['city'] as String? ?? 'Malang';
        }
      }
    }

    // 1. Cari kurir aktif yang tersedia di kota yang sama
    String courierId = '';
    String courierName = 'Kurir';

    final activeSnap = await _db
        .collection('courier_applications')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .where('area', isEqualTo: targetCity)
        .get();

    var activeDocs = activeSnap.docs.toList();

    // Fallback: jika tidak ada kurir aktif, ambil semua kurir approved
    if (activeDocs.isEmpty) {
      final allSnap = await _db
          .collection('courier_applications')
          .where('status', isEqualTo: 'approved')
          .where('area', isEqualTo: targetCity)
          .get();
      activeDocs = allSnap.docs.toList();
    }

    if (activeDocs.isNotEmpty) {
      activeDocs.shuffle();
      final courierDoc = activeDocs.first;
      courierId = courierDoc.id;
      courierName = courierDoc.data()['fullName'] as String? ?? 'Kurir';
    }

    // (sellerIds sudah diambil di atas)

    // 2. Batch write: approve return + assign courier
    final batch = _db.batch();
    batch.set(_db.collection('returns').doc(returnId), {
      'status':            'approved',
      'sellerNote':        note,
      'returnCourierId':   courierId,
      'returnCourierName': courierName,
      'orderStatus':       'return_approved',
      'sellerIds':         sellerIds, // Ensure sellerIds is present for legacy orders
      'updatedAt':         FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.update(_orders.doc(orderId), {
      'status':            'return_approved',
      'returnCourierId':   courierId,
      'returnCourierName': courierName,
      'updatedAt':         FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ── Seller tolak return ───────────────────────────────────────────────────
  Future<void> rejectReturn({
    required String returnId,
    required String orderId,
    required String note,
  }) async {
    final batch = _db.batch();
    batch.set(_db.collection('returns').doc(returnId), {
      'status':     'rejected',
      'sellerNote': note,
      'updatedAt':  FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Order kembali ke completed agar buyer masih bisa konfirmasi
    batch.update(_orders.doc(orderId), {
      'status':    'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
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
    final orderSnap = await _orders.doc(orderId).get();
    final sellerIds = orderSnap.data()?['sellerIds'] as List<dynamic>? ?? [];

    String targetCity = 'Malang';
    if (sellerIds.isNotEmpty) {
      final sellerDoc = await _db.collection('users').doc(sellerIds.first).get();
      if (sellerDoc.exists) {
        final addresses = sellerDoc.data()?['addresses'] as List<dynamic>? ?? [];
        if (addresses.isNotEmpty) {
          targetCity = addresses.first['city'] as String? ?? 'Malang';
        }
      }
    }

    // 1. Cari kurir yang AKTIF (isActive == true) di kota yang sama
    final activeSnap = await _db
        .collection('courier_applications')
        .where('status',   isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .where('area', isEqualTo: targetCity)
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
          .where('area', isEqualTo: targetCity)
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
