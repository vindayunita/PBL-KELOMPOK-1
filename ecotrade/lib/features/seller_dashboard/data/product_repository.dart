import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/product_model.dart';

part 'product_repository.g.dart';

@riverpod
ProductRepository productRepository(Ref ref) {
  return ProductRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
}

/// Stream produk milik seller yang sedang login — reaktif terhadap auth state
@riverpod
Stream<List<ProductModel>> myProducts(Ref ref) {
  final repo = ref.watch(productRepositoryProvider);
  // Gunakan authStateChanges agar stream ikut hidup saat Firebase Auth siap
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return repo.watchMyProducts(user.uid);
  });
}

class ProductRepository {
  const ProductRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('products');

  // ── Stream semua produk milik seller tertentu ─────────────────────────────
  Stream<List<ProductModel>> watchMyProducts(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map(ProductModel.fromFirestore).toList();
          // Sort client-side: produk terbaru di atas
          docs.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(2000);
            final bDate = b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });
          return docs;
        });
  }

  // ── Tambah produk baru ────────────────────────────────────────────────────
  Future<void> addProduct({
    required String title,
    required String description,
    required String commodityType,
    required double price,
    required int stock,
    String unit = 'kg',
    String imageUrl = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final sellerName = user.displayName ?? user.email ?? 'Seller';

    await _col.add({
      'title': title,
      'description': description,
      'commodityType': commodityType,
      'price': price,
      'unit': unit,
      'stock': stock,
      'badge': commodityType,
      'imageUrl': imageUrl,
      'sellerId': user.uid,
      'sellerName': sellerName,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Update produk ─────────────────────────────────────────────────────────
  Future<void> updateProduct(String id, Map<String, dynamic> data) {
    return _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Hapus produk ──────────────────────────────────────────────────────────
  Future<void> deleteProduct(String id) => _col.doc(id).delete();
}
