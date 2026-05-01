import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    required String address,
    required String commodityType,
    required String commodityDescription,
    required int stock,
    required double pricePerKg,
    File? commodityImage,
  }) async {
    state = const AsyncLoading();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = AsyncError(Exception('User belum login'), StackTrace.current);
      return;
    }

    final repo = ref.read(sellerApplicationRepositoryProvider);

    final app = SellerApplicationModel(
      uid:                 user.uid,
      name:                user.displayName ?? user.email ?? '',
      email:               user.email ?? '',
      businessName:        businessName,
      commodityType:       commodityType,
      businessDescription: '$address\n\n$commodityDescription',
      status:              'pending',
      submittedAt:         DateTime.now().toIso8601String(),
    );

    state = await AsyncValue.guard(() => repo.submitApplication(app));
  }
}
