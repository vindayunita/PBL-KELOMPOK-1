import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../user/data/user_repository.dart';
import '../domain/models/seller_application_model.dart';

part 'seller_application_repository.g.dart';

@riverpod
SellerApplicationRepository sellerApplicationRepository(Ref ref) =>
    SellerApplicationRepository(ref.watch(firestoreProvider));

class SellerApplicationRepository {
  SellerApplicationRepository(this._db);
  final FirebaseFirestore _db;

  static const _col = 'seller_applications';

  CollectionReference<Map<String, dynamic>> get _apps => _db.collection(_col);

  // ── Buyer: ajukan pendaftaran ─────────────────────────────────────────────
  Future<void> submitApplication(SellerApplicationModel app) {
    return _apps.doc(app.uid).set({
      ...app.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Buyer: watch status aplikasi miliknya ─────────────────────────────────
  Stream<SellerApplicationModel?> watchApplication(String uid) {
    return _apps.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!
        ..remove('createdAt')
        ..remove('updatedAt');
      return SellerApplicationModel.fromJson(data, snap.id);
    });
  }

  // ── Admin: watch semua aplikasi (real-time) ───────────────────────────────
  Stream<List<SellerApplicationModel>> watchAllApplications({String? status}) {
    // Ambil semua dokumen tanpa orderBy agar tidak butuh composite index.
    // Sorting & filtering dilakukan di sisi client.
    return _apps.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = {...doc.data()}
          ..remove('createdAt')
          ..remove('updatedAt');
        return SellerApplicationModel.fromJson(data, doc.id);
      }).toList();

      // Filter berdasarkan status (jika ada)
      final filtered =
          status != null ? list.where((a) => a.status == status).toList() : list;

      // Sort berdasarkan createdAt descending (via reviewedAt sebagai fallback)
      filtered.sort((a, b) => b.uid.compareTo(a.uid)); // fallback: uid desc
      return filtered;
    });
  }

  // ── Admin: approve ────────────────────────────────────────────────────────
  Future<void> approveApplication(String uid) async {
    // 1. Baca data aplikasi seller (sudah termasuk stock, price, imageUrl)
    final appSnap = await _apps.doc(uid).get();
    final appData = appSnap.data() ?? {};

    // 2. Baca data user (nama)
    final userSnap = await _db.collection('users').doc(uid).get();
    final userName = userSnap.data()?['name'] as String? ??
        userSnap.data()?['email'] as String? ??
        'Seller';

    final batch = _db.batch();

    // 3. Update status aplikasi
    batch.update(_apps.doc(uid), {
      'status':     'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    // 4. Tambah role 'seller' ke user document
    batch.update(_db.collection('users').doc(uid), {
      'roles':     FieldValue.arrayUnion(['seller']),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 5. Buat produk pertama dari data registrasi seller
    final productName         = appData['productName']         as String? ?? '';
    final businessName        = appData['businessName']        as String? ?? 'Produk Seller';
    final commodityType       = appData['commodityType']       as String? ?? '';
    final businessDescription = appData['businessDescription'] as String? ?? '';
    final stock               = (appData['stock']      as num?)?.toInt()    ?? 0;
    final price               = (appData['pricePerKg'] as num?)?.toDouble() ?? 0.0;
    final imageUrl            = appData['commodityImageUrl']   as String? ?? '';

    final productRef = _db.collection('products').doc();
    batch.set(productRef, {
      'title':         productName.isNotEmpty ? productName : businessName,
      'description':   businessDescription,
      'commodityType': commodityType,
      'price':         price,
      'unit':          'kg',
      'stock':         stock,
      'badge':         commodityType,
      'imageUrl':      imageUrl,
      'sellerId':      uid,
      'sellerName':    userName,
      'status':        'active',
      'createdAt':     FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Admin: reject ─────────────────────────────────────────────────────────
  Future<void> rejectApplication(String uid, String reason) {
    return _apps.doc(uid).update({
      'status':          'rejected',
      'rejectionReason': reason,
      'reviewedAt':      DateTime.now().toIso8601String(),
      'updatedAt':       FieldValue.serverTimestamp(),
    });
  }
}
