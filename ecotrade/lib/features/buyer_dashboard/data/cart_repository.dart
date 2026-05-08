import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'cart_item_model.dart';

part 'cart_repository.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
CartRepository cartRepository(Ref ref) {
  return CartRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reactive stream of current user's cart items
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
Stream<List<CartItemModel>> cartItems(Ref ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return repo.watchCartItems(user.uid);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────
class CartRepository {
  CartRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) =>
      _db.collection('carts').doc(uid).collection('items');

  // ── Watch all cart items ─────────────────────────────────────────────────
  Stream<List<CartItemModel>> watchCartItems(String uid) {
    return _itemsCol(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CartItemModel.fromFirestore).toList());
  }

  // ── Add or merge item into cart ──────────────────────────────────────────
  Future<void> addToCart({
    required String productId,
    required String productTitle,
    required String productImageUrl,
    required double productPrice,
    required String unit,
    required String purchaseType,
    required String sellerId,
    required String sellerName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final col = _itemsCol(user.uid);

    // Check if same product + same purchase type already in cart → merge qty
    final existing = await col
        .where('productId', isEqualTo: productId)
        .where('purchaseType', isEqualTo: purchaseType)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final currentQty = (doc.data()['quantity'] as num?)?.toInt() ?? 1;
      await doc.reference.update({'quantity': currentQty + 1});
    } else {
      await col.add({
        'productId': productId,
        'productTitle': productTitle,
        'productImageUrl': productImageUrl,
        'productPrice': productPrice,
        'unit': unit,
        'purchaseType': purchaseType,
        'quantity': 1,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Update quantity of a cart item ───────────────────────────────────────
  Future<void> updateQuantity(String itemId, int qty) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (qty <= 0) {
      await removeItem(itemId);
    } else {
      await _itemsCol(user.uid).doc(itemId).update({'quantity': qty});
    }
  }

  // ── Remove a cart item ───────────────────────────────────────────────────
  Future<void> removeItem(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _itemsCol(user.uid).doc(itemId).delete();
  }

  // ── Clear all cart items ─────────────────────────────────────────────────
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snap = await _itemsCol(user.uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
