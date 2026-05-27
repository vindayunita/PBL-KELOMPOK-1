import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/order_repository.dart';
import '../domain/order_model.dart';

part 'order_providers.g.dart';

/// Stream orders milik seller yang sedang login
@riverpod
Stream<List<OrderModel>> mySellerOrders(Ref ref) {
  // Gunakan currentUserProvider dari Riverpod agar reaktif terhadap perubahan auth
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchOrdersBySeller(user.uid);
}

/// Stream SEMUA tugas kurir yang sedang login (tanpa filter status)
/// Filter dilakukan di UI untuk fleksibilitas
@riverpod
Stream<List<OrderModel>> myCourierTasks(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchOrdersByCourier(user.uid);
}

/// Stream tugas retur kurir yang sedang login
@riverpod
Stream<List<OrderModel>> myCourierReturnTasks(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchReturnTasksByCourier(user.uid);
}

/// Stream tugas retur SELESAI kurir yang sedang login
@riverpod
Stream<List<OrderModel>> myCourierHistoryReturnTasks(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchHistoryReturnTasksByCourier(user.uid);
}

/// Stream orders berdasarkan status (untuk admin)
@riverpod
Stream<List<OrderModel>> ordersByStatus(Ref ref, String status) {
  return ref.watch(orderRepositoryProvider).watchOrdersByStatus(status);
}
