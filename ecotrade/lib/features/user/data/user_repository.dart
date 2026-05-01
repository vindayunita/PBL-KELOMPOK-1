import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models/user_model.dart';

part 'user_repository.g.dart';

@riverpod
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

@riverpod
UserRepository userRepository(Ref ref) =>
    UserRepository(ref.watch(firestoreProvider));

class UserRepository {
  const UserRepository(this._db);
  final FirebaseFirestore _db;

  static const _col = 'users';

  CollectionReference<Map<String, dynamic>> get _users => _db.collection(_col);

  Future<void> createUser(UserModel user) {
    final data = user.toJson()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    return _users.doc(user.uid).set(data);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromJson(_sanitize(snap.data()!, snap.id));
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromJson(_sanitize(snap.data()!, snap.id));
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> data, String uid) {
    return {
      ...data
        ..remove('createdAt')
        ..remove('updatedAt'),
      'uid': uid,
    };
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? address,
    String? photoUrl,
  }) {
    return _users.doc(uid).update({
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActiveRole(String uid, String role) {
    return _users.doc(uid).update({
      'activeRole': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addRole(String uid, String role) {
    return _users.doc(uid).update({
      'roles': FieldValue.arrayUnion([role]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAddresses(
      String uid, List<Map<String, dynamic>> addresses) {
    return _users.doc(uid).update({
      'addresses': addresses,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
