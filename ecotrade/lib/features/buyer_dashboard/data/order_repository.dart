import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'order_item_model.dart';

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
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  /// Upload payment proof bytes → Firebase Storage → returns download URL
  Future<String> uploadPaymentProof(Uint8List bytes, String ext) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final path =
        'payment_proofs/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return ref.getDownloadURL();
  }

  /// Save order to Firestore → returns new order ID
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
      'orderId': ref.id,
      'buyerId': user.uid,
      'buyerEmail': user.email ?? '',
      'buyerAddress': buyerAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'total': total,
      'paymentProofUrl': paymentProofUrl,
      'status': 'pending_verification', // pending_verification → verified → shipped → done
      'paymentMethod': 'bank_transfer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
