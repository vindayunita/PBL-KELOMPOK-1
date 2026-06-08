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

  // ── Username utilities ────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _db.collection('usernames');

  /// Cek apakah username sudah digunakan (baca koleksi publik /usernames).
  Future<bool> isUsernameAvailable(String username) async {
    final snap = await _usernames.doc(username.toLowerCase()).get();
    return !snap.exists;
  }

  /// Lookup email berdasarkan username (untuk login via username).
  Future<String?> getEmailByUsername(String username) async {
    final snap = await _usernames.doc(username.toLowerCase()).get();
    if (!snap.exists) return null;
    return snap.data()?['email'] as String?;
  }

  /// Lookup user berdasarkan username (untuk login via username).
  Future<UserModel?> getUserByUsername(String username) async {
    final email = await getEmailByUsername(username.toLowerCase());
    if (email == null) return null;
    final snap = await _users.where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return UserModel.fromJson(_sanitize(doc.data(), doc.id));
  }

  /// Simpan klaim username ke koleksi /usernames/{username}.
  /// Dipanggil setelah createUser agar username ter-index.
  Future<void> saveUsername(String username, String uid, String email) {
    return _usernames.doc(username.toLowerCase()).set({
      'uid': uid,
      'email': email,
    });
  }

  /// Generate username unik dari [name].
  /// Contoh: "John Doe" → "johndoe", kalau sudah ada → "johndoe1", dst.
  static String _toBaseUsername(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // hanya huruf & angka
  }

  /// Mengambil username unik. Cek koleksi /usernames dan tambahkan angka suffix jika perlu.
  Future<String> generateUniqueUsername(String name) async {
    final base = _toBaseUsername(name);
    if (base.isEmpty) return 'user${DateTime.now().millisecondsSinceEpoch}';

    // Cek base username dulu
    if (await isUsernameAvailable(base)) return base;

    // Tambah suffix angka hingga ditemukan yang kosong
    for (int i = 1; i <= 9999; i++) {
      final candidate = '$base$i';
      if (await isUsernameAvailable(candidate)) return candidate;
    }

    // Fallback dengan timestamp (sangat jarang terjadi)
    return '$base${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Update field username di dokumen user (untuk akun lama yang belum punya username).
  Future<void> updateUsername({required String uid, required String username}) {
    return _users.doc(uid).update({
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Profile ───────────────────────────────────────────────────────────────

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

  /// Removes the photoUrl field entirely from Firestore (sets it to null).
  Future<void> removePhoto(String uid) {
    return _users.doc(uid).update({
      'photoUrl': FieldValue.delete(),
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

