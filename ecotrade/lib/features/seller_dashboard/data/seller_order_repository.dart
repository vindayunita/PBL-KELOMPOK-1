import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/notifications/notification_trigger.dart';
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

/// Stream total payout yang sudah di-APPROVE admin untuk seller yang login.
/// Dipakai di UI agar saldo hanya berkurang setelah admin konfirmasi,
/// bukan langsung berkurang saat seller mengajukan request.
final sellerApprovedPayoutTotalProvider = StreamProvider<double>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0.0);
  return FirebaseFirestore.instance
      .collection('payouts')
      .where('userId', isEqualTo: uid)
      .where('userRole', isEqualTo: 'seller')
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((snap) => snap.docs.fold<double>(
            0.0,
            (sum, doc) =>
                sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0),
          ));
});



// ── Repository ────────────────────────────────────────────────────────────────
class SellerOrderRepository {
  SellerOrderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Ambil kota seller dengan prioritas:
  /// 1. `seller_applications/{sellerId}.city`  ← disimpan saat registrasi seller
  /// 2. `users/{sellerId}/addresses[0].city`   ← fallback jika seller_applications kosong
  /// 3. Default `'Malang'`
  /// Hasil selalu dinormalisasi ke Title Case agar cocok dengan field `area` kurir.
  Future<String> _getSellerCity(String sellerId) async {
    // Prioritas 1: seller_applications
    final appDoc = await _db.collection('seller_applications').doc(sellerId).get();
    if (appDoc.exists) {
      final city = appDoc.data()?['city'] as String?;
      if (city != null && city.trim().isNotEmpty) {
        return _normalizeCity(city);
      }
    }
    // Prioritas 2: users.addresses
    final userDoc = await _db.collection('users').doc(sellerId).get();
    if (userDoc.exists) {
      final addresses = userDoc.data()?['addresses'] as List<dynamic>? ?? [];
      if (addresses.isNotEmpty) {
        final city = addresses.first['city'] as String?;
        if (city != null && city.trim().isNotEmpty) {
          return _normalizeCity(city);
        }
      }
    }
    return 'Malang'; // default
  }

  /// Normalisasi nama kota ke Title Case.
  /// Contoh: "malang" → "Malang", "KOTA BATU" → "Kota Batu"
  static String _normalizeCity(String city) {
    if (city.trim().isEmpty) return city;
    return city.trim().split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

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

    final targetCity = sellerIds.isNotEmpty
        ? await _getSellerCity(sellerIds.first as String)
        : 'Malang';

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

    // 2. Batch write: approve return + assign courier (status: return_assigned = menunggu konfirmasi kurir)
    final batch = _db.batch();
    batch.set(_db.collection('returns').doc(returnId), {
      'status':            'approved',
      'sellerNote':        note,
      'returnCourierId':   courierId,
      'returnCourierName': courierName,
      'orderStatus':       'return_assigned',
      'sellerIds':         sellerIds, // Ensure sellerIds is present for legacy orders
      'updatedAt':         FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.update(_orders.doc(orderId), {
      'status':            'return_assigned',
      'returnCourierId':   courierId,
      'returnCourierName': courierName,
      'updatedAt':         FieldValue.serverTimestamp(),
    });
    await batch.commit();

    // 🔔 Notifikasi ke buyer bahwa retur disetujui
    final orderSnap2 = await _orders.doc(orderId).get();
    final buyerId    = orderSnap2.data()?['buyerId'] as String? ?? '';
    unawaited(NotificationTrigger.returnApproved(
      buyerId: buyerId,
      orderId: orderId,
    ));
    // 🔔 Notifikasi ke kurir yang ditugaskan
    if (courierId.isNotEmpty) {
      final buyerAddress = orderSnap2.data()?['buyerAddress'] as String? ?? '';
      unawaited(NotificationTrigger.returnTaskAssigned(
        courierId:    courierId,
        orderId:      orderId,
        buyerAddress: buyerAddress,
      ));
    }
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

    // 🔔 Notifikasi ke buyer bahwa retur ditolak
    final orderSnap2 = await _orders.doc(orderId).get();
    final buyerId    = orderSnap2.data()?['buyerId'] as String? ?? '';
    unawaited(NotificationTrigger.returnRejected(
      buyerId: buyerId,
      orderId: orderId,
      reason:  note,
    ));
  }
  Future<void> acceptOrder(String orderId) async {
    // Ambil data order terlebih dahulu agar bisa mengirim notifikasi
    final orderSnap = await _orders.doc(orderId).get();
    final data      = orderSnap.data();
    final buyerId   = data?['buyerId']  as String? ?? '';
    final sellerIds = (data?['sellerIds'] as List<dynamic>? ?? []).cast<String>();
    final items     = (data?['items']   as List<dynamic>? ?? []);
    final firstItem = items.isNotEmpty ? items.first as Map<String, dynamic> : null;
    final productTitle = firstItem?['productTitle'] as String? ?? 'pesanan';

    await _orders.doc(orderId).update({
      'status':    'processing',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Notifikasi ke buyer
    unawaited(NotificationTrigger.orderProcessing(
      buyerId:      buyerId,
      orderId:      orderId,
      productTitle: productTitle,
    ));

    // 🔔 Notifikasi ke semua seller yang terlibat (jika multi-seller)
    for (final sid in sellerIds) {
      unawaited(NotificationTrigger.newOrderForSeller(
        sellerId:     sid,
        orderId:      orderId,
        productTitle: productTitle,
        buyerName:    data?['buyerName'] as String? ?? 'Pembeli',
      ));
    }
  }

  // ── Seller tolak order → rejected ────────────────────────────────────────
  /// Menolak order dan mengembalikan stok produk yang sudah dikurangi
  /// saat admin memverifikasi pembayaran.
  Future<void> rejectOrder(String orderId, String reason) async {
    // 1. Baca order untuk mendapatkan items dan mengembalikan stok
    final orderSnap = await _orders.doc(orderId).get();
    if (!orderSnap.exists) throw Exception('Order $orderId tidak ditemukan');

    final data     = orderSnap.data()!;
    final rawItems = data['items'] as List<dynamic>? ?? [];

    final batch = _db.batch();

    // 2. Update status order
    batch.update(_orders.doc(orderId), {
      'status':          'rejected',
      'rejectionReason': reason,
      'updatedAt':       FieldValue.serverTimestamp(),
    });

    // 3. Kembalikan stok setiap produk
    for (final raw in rawItems) {
      final item      = raw as Map<String, dynamic>;
      final productId = item['productId'] as String?;
      final quantity  = (item['quantity'] as num?)?.toInt() ?? 0;
      if (productId == null || productId.isEmpty || quantity <= 0) continue;

      final productRef = _db.collection('products').doc(productId);
      batch.update(productRef, {
        'stock':     FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ── Seller assign kurir otomatis → assigned ──────────────────────────────
  Future<void> assignCourier(String orderId, {String? excludeCourierId}) async {
    final orderSnap = await _orders.doc(orderId).get();
    final sellerIds = orderSnap.data()?['sellerIds'] as List<dynamic>? ?? [];

    final targetCity = sellerIds.isNotEmpty
        ? await _getSellerCity(sellerIds.first as String)
        : 'Malang';

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

    // 🔔 Notifikasi ke buyer
    final orderSnap2 = await _orders.doc(orderId).get();
    final buyerId    = orderSnap2.data()?['buyerId']     as String? ?? '';
    final buyerAddr  = orderSnap2.data()?['buyerAddress'] as String? ?? '';
    unawaited(NotificationTrigger.courierAssigned(
      buyerId:     buyerId,
      orderId:     orderId,
      courierName: courierName,
    ));
    // 🔔 Notifikasi ke kurir
    unawaited(NotificationTrigger.courierTaskAssigned(
      courierId:   courierId,
      orderId:     orderId,
      sellerCity:  targetCity,
      buyerAddress: buyerAddr,
    ));
  }

  // ── Re-assign ke kurir lain (dipanggil saat kurir tolak tugas) ───────────
  Future<void> reAssignCourier(String orderId, String rejectedCourierId) {
    return assignCourier(orderId, excludeCourierId: rejectedCourierId);
  }

  // ── Tugaskan ulang kurir untuk retur (setelah kurir menolak) ─────────────
  /// Menemukan kurir aktif baru dan mengupdate KEDUA koleksi (orders + returns).
  Future<void> reassignReturnCourier({
    required String returnId,
    required String orderId,
    String? excludeCourierId,
  }) async {
    // Ambil kota seller
    final orderSnap = await _orders.doc(orderId).get();
    final sellerIds = orderSnap.data()?['sellerIds'] as List<dynamic>? ?? [];

    final targetCity = sellerIds.isNotEmpty
        ? await _getSellerCity(sellerIds.first as String)
        : 'Malang';

    // Cari kurir aktif baru (kecualikan yang menolak)
    String courierId = '';
    String courierName = 'Kurir';

    final activeSnap = await _db
        .collection('courier_applications')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .where('area', isEqualTo: targetCity)
        .get();

    var activeDocs = excludeCourierId != null
        ? activeSnap.docs.where((d) => d.id != excludeCourierId).toList()
        : activeSnap.docs.toList();

    // Fallback: tanpa filter isActive
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
      throw Exception('Tidak ada kurir tersedia untuk ditugaskan ulang.');
    }

    activeDocs.shuffle();
    final courierDoc = activeDocs.first;
    courierId = courierDoc.id;
    courierName = courierDoc.data()['fullName'] as String? ?? 'Kurir';

    // Batch update kedua koleksi sekaligus
    final batch = _db.batch();
    batch.update(_orders.doc(orderId), {
      'status':            'return_assigned',
      'returnCourierId':   courierId,
      'returnCourierName': courierName,
      'updatedAt':         FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('returns').doc(returnId), {
      'returnCourierId':   courierId,
      'returnCourierName': courierName,
      'orderStatus':       'return_assigned',
      'updatedAt':         FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  // ── Seller mark selesai → completed ──────────────────────────────────────
  Future<void> completeOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status':    'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Balas Ulasan ─────────────────────────────────────────────────────────
  Future<void> replyToReview({
    required String reviewId,
    required String replyText,
  }) async {
    await _db.collection('reviews').doc(reviewId).update({
      'sellerReply': replyText,
      'repliedAt':   FieldValue.serverTimestamp(),
    });
  }
}
