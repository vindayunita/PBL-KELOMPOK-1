import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'order_item_model.dart';
import 'order_model.dart';

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

    final ref = _db.collection('orders').doc();
    await ref.set({
      'orderId':        ref.id,
      'buyerId':        user.uid,
      'buyerEmail':     user.email ?? '',
      'buyerAddress':   buyerAddress,
      'items':          items.map((i) => i.toJson()).toList(),
      'total':          total,
      'paymentProofUrl': paymentProofUrl,
      'status':         'pending_verification',
      'paymentMethod':  'bank_transfer',
      'createdAt':      FieldValue.serverTimestamp(),
      'updatedAt':      FieldValue.serverTimestamp(),
    });
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
  Future<void> submitReview({
    required String orderId,
    required int    rating,
    required String reviewText,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'rating':     rating,
      'reviewText': reviewText,
      'updatedAt':  FieldValue.serverTimestamp(),
    });
  }

  // ── Request return ───────────────────────────────────────────────────────
  Future<void> requestReturn({
    required String orderId,
    required String reason,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':       'return_requested',
      'returnReason': reason,
      'updatedAt':    FieldValue.serverTimestamp(),
    });
  }
}
