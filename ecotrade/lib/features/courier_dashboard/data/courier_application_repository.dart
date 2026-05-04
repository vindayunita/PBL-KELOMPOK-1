import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../user/data/user_repository.dart';
import '../domain/models/courier_application_model.dart';

part 'courier_application_repository.g.dart';

@riverpod
CourierApplicationRepository courierApplicationRepository(Ref ref) =>
    CourierApplicationRepository(ref.watch(firestoreProvider));

class CourierApplicationRepository {
  CourierApplicationRepository(this._db);
  final FirebaseFirestore _db;

  static const _col = 'courier_applications';

  CollectionReference<Map<String, dynamic>> get _apps => _db.collection(_col);

  // ── User: submit aplikasi ──────────────────────────────────────────────────
  Future<void> submitApplication(CourierApplicationModel app) {
    return _apps.doc(app.uid).set({
      ...app.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── User: watch status aplikasi miliknya ──────────────────────────────────
  Stream<CourierApplicationModel?> watchApplication(String uid) {
    return _apps.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!
        ..remove('createdAt')
        ..remove('updatedAt');
      return CourierApplicationModel.fromJson(data, snap.id);
    });
  }

  // ── Admin: watch semua aplikasi (real-time) ───────────────────────────────
  Stream<List<CourierApplicationModel>> watchAllApplications({String? status}) {
    Query<Map<String, dynamic>> q =
        _apps.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((snap) => snap.docs.map((doc) {
          final data = {...doc.data()}
            ..remove('createdAt')
            ..remove('updatedAt');
          return CourierApplicationModel.fromJson(data, doc.id);
        }).toList());
  }

  // ── Admin: approve ─────────────────────────────────────────────────────────
  Future<void> approveApplication(String uid) async {
    final batch = _db.batch();
    // 1. Update status aplikasi
    batch.update(_apps.doc(uid), {
      'status':     'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
      'updatedAt':  FieldValue.serverTimestamp(),
    });
    // 2. Tambah role 'courier' ke user document
    batch.update(_db.collection('users').doc(uid), {
      'roles':     FieldValue.arrayUnion(['courier']),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ── Admin: reject ──────────────────────────────────────────────────────────
  Future<void> rejectApplication(String uid, String reason) {
    return _apps.doc(uid).update({
      'status':          'rejected',
      'rejectionReason': reason,
      'reviewedAt':      DateTime.now().toIso8601String(),
      'updatedAt':       FieldValue.serverTimestamp(),
    });
  }
}
