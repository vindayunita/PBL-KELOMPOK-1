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
    Query<Map<String, dynamic>> q = _apps.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((snap) => snap.docs.map((doc) {
          final data = {...doc.data()}
            ..remove('createdAt')
            ..remove('updatedAt');
          return SellerApplicationModel.fromJson(data, doc.id);
        }).toList());
  }

  // ── Admin: approve ────────────────────────────────────────────────────────
  Future<void> approveApplication(String uid) async {
    final batch = _db.batch();
    // 1. Update application status
    batch.update(_apps.doc(uid), {
      'status':     'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
      'updatedAt':  FieldValue.serverTimestamp(),
    });
    // 2. Tambah role 'seller' ke user document
    batch.update(_db.collection('users').doc(uid), {
      'roles':     FieldValue.arrayUnion(['seller']),
      'updatedAt': FieldValue.serverTimestamp(),
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
