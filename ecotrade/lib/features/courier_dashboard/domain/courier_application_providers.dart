import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/courier_application_repository.dart';
import 'models/courier_application_model.dart';

part 'courier_application_providers.g.dart';

/// Watch status aplikasi kurir milik user yang sedang login (real-time).
@riverpod
Stream<CourierApplicationModel?> myCourierApplication(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(courierApplicationRepositoryProvider)
      .watchApplication(user.uid);
}

/// Watch semua aplikasi kurir (untuk admin), difilter berdasarkan status.
@riverpod
Stream<List<CourierApplicationModel>> allCourierApplications(
    Ref ref, String? status) {
  return ref
      .watch(courierApplicationRepositoryProvider)
      .watchAllApplications(status: status);
}
