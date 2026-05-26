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

  // ── Seller Lama: Upload KYC tanpa mendaftar ulang ─────────────────────────
  /// Dipakai oleh seller yang sudah aktif sebelum sistem KYC diterapkan.
  /// Hanya mengupdate field KYC tanpa mengubah status/role seller.
  Future<void> submitKycOnly({
    required String uid,
    required String ktpImageUrl,
    required String selfieWithKtpImageUrl,
    required String ktpName,
    required String bankName,
    required String bankAccountName,
    required String bankAccountNumber,
  }) async {
    final batch = _db.batch();

    // Upsert dokumen seller_applications dengan data KYC
    // Jika dokumen belum ada (seller lama), buat baru dengan status approved
    final appRef = _apps.doc(uid);
    final appSnap = await appRef.get();

    if (appSnap.exists) {
      // Update dokumen yang sudah ada
      batch.update(appRef, {
        'ktpImageUrl':           ktpImageUrl,
        'selfieWithKtpImageUrl': selfieWithKtpImageUrl,
        'ktpName':               ktpName,
        'bankName':              bankName,
        'bankAccountName':       bankAccountName,
        'bankAccountNumber':     bankAccountNumber,
        'kycStatus':             'pending',
        'updatedAt':             FieldValue.serverTimestamp(),
      });
    } else {
      // Buat dokumen baru untuk seller lama (tidak punya seller_application)
      batch.set(appRef, {
        'ktpImageUrl':           ktpImageUrl,
        'selfieWithKtpImageUrl': selfieWithKtpImageUrl,
        'ktpName':               ktpName,
        'bankName':              bankName,
        'bankAccountName':       bankAccountName,
        'bankAccountNumber':     bankAccountNumber,
        'kycStatus':             'pending',
        'status':                'approved', // seller sudah aktif
        'uid':                   uid,
        'createdAt':             FieldValue.serverTimestamp(),
        'updatedAt':             FieldValue.serverTimestamp(),
      });
    }

    // Update kycStatus di users collection agar pencairan tetap terkunci
    // sampai admin memverifikasi
    batch.update(_db.collection('users').doc(uid), {
      'kycStatus':          'pending',
      'bankName':           bankName,
      'bankAccountName':    bankAccountName,
      'bankAccountNumber':  bankAccountNumber,
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await batch.commit();
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

    // 3. Update status aplikasi + kycStatus verified
    batch.update(_apps.doc(uid), {
      'status':     'approved',
      'kycStatus':  'verified',
      'reviewedAt': DateTime.now().toIso8601String(),
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    // 4. Tambah role 'seller' ke user document + update kycStatus + simpan data bank
    final bankName          = appData['bankName']          as String? ?? '';
    final bankAccountName   = appData['bankAccountName']   as String? ?? '';
    final bankAccountNumber = appData['bankAccountNumber'] as String? ?? '';

    batch.update(_db.collection('users').doc(uid), {
      'roles':              FieldValue.arrayUnion(['seller']),
      'kycStatus':          'verified',
      'bankVerifiedAt':     DateTime.now().toIso8601String(),
      'bankName':           bankName,
      'bankAccountName':    bankAccountName,
      'bankAccountNumber':  bankAccountNumber,
      'updatedAt':          FieldValue.serverTimestamp(),
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
      'kycStatus':       'rejected',
      'rejectionReason': reason,
      'reviewedAt':      DateTime.now().toIso8601String(),
      'updatedAt':       FieldValue.serverTimestamp(),
    });
  }

  // ── Admin: approve KYC saja (untuk seller lama / re-verifikasi bank) ──────
  /// Berbeda dari approveApplication():
  /// - TIDAK membuat produk baru
  /// - TIDAK mengubah role user (sudah seller)
  /// - Hanya mengupdate kycStatus → 'verified' di kedua koleksi
  /// Dipakai untuk:
  ///   1. Seller lama yang baru pertama kali upload KYC
  ///   2. Seller yang mengubah data bank (re-verifikasi)
  Future<void> approveKycOnly(String uid) async {
    final appSnap = await _apps.doc(uid).get();
    final appData = appSnap.data() ?? {};

    final bankName          = appData['bankName']          as String? ?? '';
    final bankAccountName   = appData['bankAccountName']   as String? ?? '';
    final bankAccountNumber = appData['bankAccountNumber'] as String? ?? '';

    final batch = _db.batch();

    batch.update(_apps.doc(uid), {
      'kycStatus':  'verified',
      'reviewedAt': DateTime.now().toIso8601String(),
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('users').doc(uid), {
      'kycStatus':          'verified',
      'bankVerifiedAt':     DateTime.now().toIso8601String(),
      'bankName':           bankName,
      'bankAccountName':    bankAccountName,
      'bankAccountNumber':  bankAccountNumber,
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Admin: reject KYC saja (untuk seller lama / re-verifikasi bank) ───────
  Future<void> rejectKycOnly(String uid, String reason) async {
    final batch = _db.batch();

    batch.update(_apps.doc(uid), {
      'kycStatus':       'rejected',
      'rejectionReason': reason,
      'reviewedAt':      DateTime.now().toIso8601String(),
      'updatedAt':       FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('users').doc(uid), {
      'kycStatus':  'rejected',
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }


  /// Dipanggil ketika seller mengubah data bank.
  /// Akan mereset kycStatus menjadi 'pending' sehingga pencairan diblokir
  /// sampai admin memverifikasi ulang kecocokan nama KTP dan rekening baru.
  Future<void> updateBankData({
    required String uid,
    required String bankName,
    required String bankAccountName,
    required String bankAccountNumber,
  }) async {
    final batch = _db.batch();

    // Update di seller_applications
    batch.update(_apps.doc(uid), {
      'bankName':           bankName,
      'bankAccountName':    bankAccountName,
      'bankAccountNumber':  bankAccountNumber,
      'kycStatus':          'pending',
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    // Reset kycStatus di users collection agar pencairan diblokir
    batch.update(_db.collection('users').doc(uid), {
      'bankName':           bankName,
      'bankAccountName':    bankAccountName,
      'bankAccountNumber':  bankAccountNumber,
      'kycStatus':          'pending',
      'bankVerifiedAt':     null,
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Admin: re-approve KYC setelah update bank ─────────────────────────────
  Future<void> reapproveKyc(String uid) async {
    final batch = _db.batch();

    batch.update(_apps.doc(uid), {
      'kycStatus':  'verified',
      'reviewedAt': DateTime.now().toIso8601String(),
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('users').doc(uid), {
      'kycStatus':      'verified',
      'bankVerifiedAt': DateTime.now().toIso8601String(),
      'updatedAt':      FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
