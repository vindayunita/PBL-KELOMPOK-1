import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/seller_application_repository.dart';
import '../../domain/models/seller_application_model.dart';

part 'seller_registration_controller.g.dart';

@riverpod
class SellerRegistrationController extends _$SellerRegistrationController {
  @override
  FutureOr<void> build() {}

  Future<void> submitRegistration({
    required String businessName,
    required String productName,
    required String address,
    required String commodityType,
    required String commodityDescription,
    required int stock,
    required double pricePerKg,
    String? city,
    XFile? commodityImage,
    // ── KYC Parameters ──────────────────────────────────────────────────────
    required XFile ktpImage,
    required XFile selfieImage,
    required String ktpName,
    required String bankName,
    required String bankAccountName,
    required String bankAccountNumber,
  }) async {
    state = const AsyncLoading();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = AsyncError(Exception('User belum login'), StackTrace.current);
      return;
    }

    state = await AsyncValue.guard(() async {
      // 1. Upload gambar komoditi (opsional)
      String commodityImageUrl = '';
      if (commodityImage != null) {
        try {
          final bytes = await commodityImage.readAsBytes();
          final ext = commodityImage.name.split('.').last.toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          final ref = FirebaseStorage.instance
              .ref()
              .child('seller_registrations/${user.uid}/commodity_${DateTime.now().millisecondsSinceEpoch}.$ext');
          await ref.putData(bytes, SettableMetadata(contentType: mime));
          commodityImageUrl = await ref.getDownloadURL();
        } catch (_) {
          // Jika Storage gagal, lanjut tanpa gambar komoditi
        }
      }

      // 2. Upload foto KTP (wajib)
      String ktpImageUrl = '';
      try {
        final ktpBytes = await ktpImage.readAsBytes();
        final ktpExt = ktpImage.name.split('.').last.toLowerCase();
        final ktpMime = ktpExt == 'png' ? 'image/png' : 'image/jpeg';
        final ktpRef = FirebaseStorage.instance
            .ref()
            .child('kyc/${user.uid}/ktp_${DateTime.now().millisecondsSinceEpoch}.$ktpExt');
        await ktpRef.putData(ktpBytes, SettableMetadata(contentType: ktpMime));
        ktpImageUrl = await ktpRef.getDownloadURL();
      } catch (e) {
        throw Exception('Gagal mengupload foto KTP: $e');
      }

      // 3. Upload foto selfie + KTP (wajib)
      String selfieImageUrl = '';
      try {
        final selfieBytes = await selfieImage.readAsBytes();
        final selfieExt = selfieImage.name.split('.').last.toLowerCase();
        final selfieMime = selfieExt == 'png' ? 'image/png' : 'image/jpeg';
        final selfieRef = FirebaseStorage.instance
            .ref()
            .child('kyc/${user.uid}/selfie_${DateTime.now().millisecondsSinceEpoch}.$selfieExt');
        await selfieRef.putData(selfieBytes, SettableMetadata(contentType: selfieMime));
        selfieImageUrl = await selfieRef.getDownloadURL();
      } catch (e) {
        throw Exception('Gagal mengupload foto selfie: $e');
      }

      // 4. Simpan semua data ke seller_applications
      final repo = ref.read(sellerApplicationRepositoryProvider);
      final app = SellerApplicationModel(
        uid:                 user.uid,
        name:                user.displayName ?? user.email ?? '',
        email:               user.email ?? '',
        businessName:        businessName,
        commodityType:       commodityType,
        businessDescription: '$address\n\n$commodityDescription',
        city:                city,
        productName:         productName,
        stock:               stock,
        pricePerKg:          pricePerKg,
        commodityImageUrl:   commodityImageUrl,
        status:              'pending',
        kycStatus:           'pending',
        submittedAt:         DateTime.now().toIso8601String(),
        // KYC data
        ktpImageUrl:          ktpImageUrl,
        selfieWithKtpImageUrl:selfieImageUrl,
        ktpName:              ktpName,
        bankName:             bankName,
        bankAccountName:      bankAccountName,
        bankAccountNumber:    bankAccountNumber,
      );

      await repo.submitApplication(app);
    });
  }
}
