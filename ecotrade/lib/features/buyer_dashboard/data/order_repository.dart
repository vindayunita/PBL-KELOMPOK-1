import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/notifications/notification_trigger.dart';

import 'order_item_model.dart';
import 'order_model.dart';
import 'review_model.dart';

part 'order_repository.g.dart';

@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    FirebaseStorage.instance,
  );
}

class OrderRepository {
  OrderRepository(this._db, this._auth, this._storage);

  final FirebaseFirestore _db;
  final FirebaseAuth     _auth;
  final FirebaseStorage  _storage;

  // ── Upload payment proof ─────────────────────────────────────────────────
  Future<String> uploadPaymentProof(Uint8List bytes, String ext) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final path =
        'payment_proofs/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return ref.getDownloadURL();
  }

  // ── Place order ──────────────────────────────────────────────────────────
  Future<String> placeOrder({
    required List<OrderItem> items,
    required String buyerAddress,
    required double total,
    required String paymentProofUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Kumpulkan semua sellerId unik agar seller bisa query dgn arrayContains
    final sellerIds = items.map((i) => i.sellerId).toSet().toList();

    // Ambil alamat lengkap seller pertama dari Firestore
    String sellerAddress = '';
    if (sellerIds.isNotEmpty) {
      try {
        final sellerDoc =
            await _db.collection('users').doc(sellerIds.first).get();
        final addresses =
            sellerDoc.data()?['addresses'] as List<dynamic>? ?? [];
        if (addresses.isNotEmpty) {
          final addr = addresses.first as Map<String, dynamic>;
          final parts = <String>[
            if ((addr['street'] as String?)?.isNotEmpty == true)
              addr['street'] as String,
            if ((addr['detail'] as String?)?.isNotEmpty == true)
              addr['detail'] as String,
            if ((addr['district'] as String?)?.isNotEmpty == true)
              addr['district'] as String,
            if ((addr['city'] as String?)?.isNotEmpty == true)
              addr['city'] as String,
            if ((addr['province'] as String?)?.isNotEmpty == true)
              addr['province'] as String,
          ];
          sellerAddress = parts.join(', ');
          // Fallback jika tidak ada field spesifik, coba field 'address' atau 'fullAddress'
          if (sellerAddress.isEmpty) {
            sellerAddress = addr['address'] as String? ??
                addr['fullAddress'] as String? ??
                addr['city'] as String? ??
                '';
          }
        }
      } catch (_) {}
    }

    final batch = _db.batch();
    final ref = _db.collection('orders').doc();
    batch.set(ref, {
      'orderId':         ref.id,
      'buyerId':         user.uid,
      'buyerEmail':      user.email ?? '',
      'buyerName':       user.displayName ?? '',
      'buyerAddress':    buyerAddress,
      'items':           items.map((i) => i.toJson()).toList(),
      'total':           total,
      'paymentProofUrl': paymentProofUrl,
      'status':          'pending_verification',
      'paymentMethod':   'bank_transfer',
      'sellerIds':       sellerIds,
      'sellerAddress':   sellerAddress,
      'createdAt':       FieldValue.serverTimestamp(),
      'updatedAt':       FieldValue.serverTimestamp(),
    });

    final paymentRef = _db.collection('payments').doc();
    batch.set(paymentRef, {
      'paymentId':       paymentRef.id,
      'orderId':         ref.id,
      'buyerId':         user.uid,
      'buyerName':       user.displayName ?? '',
      'total':           total,
      'paymentProofUrl': paymentProofUrl,
      'status':          'pending',
      'paymentMethod':   'bank_transfer',
      'createdAt':       FieldValue.serverTimestamp(),
    });

    await batch.commit();
    
    unawaited(NotificationTrigger.adminNewPaymentVerification(ref.id));
    
    return ref.id;
  }

  // ── Stream buyer's order history ─────────────────────────────────────────
  Stream<List<OrderModel>> myOrders() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(OrderModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Submit review ────────────────────────────────────────────────────────
  // ── Submit review ────────────────────────────────────────────────────────
  /// Menyimpan review ke koleksi `reviews` (bisa dilihat semua buyer & seller) dan
  /// mengupdate dokumen `orders` dengan flag sudah review.
  Future<void> submitReview({
    required String orderId,
    required String productId,
    required String purchaseType,
    required int    rating,
    required String reviewText,
    List<({Uint8List bytes, String ext})> photos = const [],
    ({Uint8List bytes, String ext})? video,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    // 1. Upload foto ke Storage
    final photoUrls = <String>[];
    for (final photo in photos) {
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final path = 'review_photos/$productId/$orderId/$ts.${photo.ext}';
      final ref  = _storage.ref(path);
      await ref.putData(
        photo.bytes,
        SettableMetadata(contentType: 'image/${photo.ext}'),
      );
      photoUrls.add(await ref.getDownloadURL());
    }

    // 2. Upload video ke Storage (jika ada)
    String? videoUrl;
    if (video != null) {
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final path = 'review_videos/$productId/$orderId/$ts.${video.ext}';
      final ref  = _storage.ref(path);
      await ref.putData(
        video.bytes,
        SettableMetadata(contentType: 'video/${video.ext}'),
      );
      videoUrl = await ref.getDownloadURL();
    }

    final batch = _db.batch();

    // 3. Ambil sellerId dari order untuk disimpan di review
    String sellerId = '';
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      final sellerIds = (orderDoc.data()?['sellerIds'] as List<dynamic>? ?? []).cast<String>();
      sellerId = sellerIds.isNotEmpty ? sellerIds.first : '';
    } catch (_) {}

    // 4. Simpan ke koleksi `reviews` agar bisa dibaca buyer & seller
    final reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, {
      'reviewId':     reviewRef.id,
      'productId':    productId,
      'orderId':      orderId,
      'buyerId':      user.uid,
      'buyerName':    user.displayName ?? user.email?.split('@').first ?? 'Pembeli',
      'sellerId':     sellerId,    // ← agar seller bisa query by sellerId
      'rating':       rating,
      'reviewText':   reviewText,
      'photoUrls':    photoUrls,
      'videoUrl':     videoUrl,
      'purchaseType': purchaseType,
      'createdAt':    FieldValue.serverTimestamp(),
    });

    // 5. Update dokumen order: cukup flag hasReview (hindari duplikasi data)
    batch.update(_db.collection('orders').doc(orderId), {
      'hasReview':    true,
      'rating':       rating,
      'reviewText':   reviewText,
      'updatedAt':    FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Stream reviews per produk ────────────────────────────────────────────
  /// Stream semua review untuk produk tertentu, diurutkan terbaru dulu.
  /// Sorting dilakukan di client untuk menghindari kebutuhan composite index Firestore.
  Stream<List<ReviewModel>> reviewsForProduct(String productId) {
    return _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ReviewModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Request return (legacy — tanpa foto) ─────────────────────────────────
  Future<void> requestReturn({
    required String orderId,
    required String reason,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':       'return_requested',
      'returnReason': reason,
      'updatedAt':    FieldValue.serverTimestamp(),
    });

    // Ambil data order untuk notifikasi (asumsi fallback jika method ini masih dipakai)
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      final data = doc.data() ?? {};
      final sellerIds = (data['sellerIds'] as List<dynamic>? ?? []).map((e) => e as String).toList();
      final buyerName = data['buyerName'] as String? ?? 'Pembeli';
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final productTitle = rawItems.isNotEmpty ? (rawItems.first['productTitle'] as String? ?? 'Produk') : 'Produk';
      
      for (final sellerId in sellerIds) {
        unawaited(NotificationTrigger.returnRequested(
          sellerId: sellerId,
          orderId: orderId,
          productTitle: productTitle,
          buyerName: buyerName,
        ));
      }
    } catch (_) {}
  }

  // ── Request return dengan foto kondisi produk ─────────────────────────────
  /// Mengupload [photos] (Uint8List + ekstensi) ke Storage, membuat dokumen
  /// baru di koleksi `returns`, lalu mengupdate status order.
  Future<void> requestReturnWithPhotos({
    required String           orderId,
    required String           reason,
    required List<({Uint8List bytes, String ext})> photos,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    // 1. Ambil snapshot order untuk mengisi data return
    final orderDoc = await _db.collection('orders').doc(orderId).get();
    final orderData = orderDoc.data() ?? {};

    final rawItems    = orderData['items']     as List<dynamic>? ?? [];
    final firstItem   = rawItems.isNotEmpty
        ? rawItems.first as Map<String, dynamic>
        : <String, dynamic>{};
    final sellerIds   = (orderData['sellerIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    // 2. Upload setiap foto ke Firebase Storage
    final photoUrls = <String>[];
    for (final photo in photos) {
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final path = 'return_photos/$orderId/$ts.${photo.ext}';
      final ref  = _storage.ref(path);
      await ref.putData(
        photo.bytes,
        SettableMetadata(contentType: 'image/${photo.ext}'),
      );
      photoUrls.add(await ref.getDownloadURL());
    }

    // 3. Buat dokumen di koleksi `returns`
    final returnRef = _db.collection('returns').doc();
    final batch     = _db.batch();

    batch.set(returnRef, {
      'returnId':        returnRef.id,
      'orderId':         orderId,
      'buyerId':         user.uid,
      'buyerName':       orderData['buyerName']  as String? ?? user.displayName ?? '',
      'sellerIds':       sellerIds,
      'productTitle':    firstItem['productTitle']    as String? ?? '',
      'productImageUrl': firstItem['productImageUrl'] as String? ?? '',
      'total':           (orderData['total'] as num?)?.toDouble() ?? 0,
      'reason':          reason,
      'photoUrls':       photoUrls,
      'status':          'pending',
      'sellerNote':      null,
      'createdAt':       FieldValue.serverTimestamp(),
      'updatedAt':       FieldValue.serverTimestamp(),
    });

    // 4. Update dokumen order
    batch.update(_db.collection('orders').doc(orderId), {
      'status':       'return_requested',
      'returnReason': reason,
      'returnId':     returnRef.id,
      'updatedAt':    FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // 5. Kirim notifikasi ke seller
    final buyerName = orderData['buyerName'] as String? ?? user.displayName ?? 'Pembeli';
    final productTitle = firstItem['productTitle'] as String? ?? 'Produk';
    
    for (final sellerId in sellerIds) {
      unawaited(NotificationTrigger.returnRequested(
        sellerId: sellerId,
        orderId: orderId,
        productTitle: productTitle,
        buyerName: buyerName,
      ));
    }
  }

  // ── Confirm order received ───────────────────────────────────────────────
  Future<void> confirmOrderReceived(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status':    'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
