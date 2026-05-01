import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/seller_application_repository.dart';
import 'models/seller_application_model.dart';

part 'seller_application_providers.g.dart';

/// Watch status aplikasi seller milik user yang sedang login (real-time).
@riverpod
Stream<SellerApplicationModel?> mySellerApplication(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(sellerApplicationRepositoryProvider).watchApplication(user.uid);
}

/// Watch semua aplikasi (untuk admin), difilter berdasarkan status.
@riverpod
Stream<List<SellerApplicationModel>> allSellerApplications(
    Ref ref, String? status) {
  return ref
      .watch(sellerApplicationRepositoryProvider)
      .watchAllApplications(status: status);
}
