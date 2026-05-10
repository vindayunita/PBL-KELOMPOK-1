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
  }) async {
    state = const AsyncLoading();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = AsyncError(Exception('User belum login'), StackTrace.current);
      return;
    }

    state = await AsyncValue.guard(() async {
      // 1. Upload gambar ke Firebase Storage (web-compatible via putData)
      String imageUrl = '';
      if (commodityImage != null) {
        try {
          final bytes = await commodityImage.readAsBytes();
          final ext = commodityImage.name.split('.').last.toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          final ref = FirebaseStorage.instance
              .ref()
              .child('seller_registrations/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext');
          await ref.putData(bytes, SettableMetadata(contentType: mime));
          imageUrl = await ref.getDownloadURL();
        } catch (_) {
          // Jika Storage gagal, lanjut tanpa gambar
        }
      }

      // 2. Simpan semua data (termasuk produk) ke seller_applications
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
        commodityImageUrl:   imageUrl,
        status:              'pending',
        submittedAt:         DateTime.now().toIso8601String(),
      );

      await repo.submitApplication(app);
    });
  }
}
