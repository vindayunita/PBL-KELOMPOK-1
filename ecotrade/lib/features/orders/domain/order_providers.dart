import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/order_repository.dart';
import '../domain/order_model.dart';

part 'order_providers.g.dart';

/// Stream orders milik seller yang sedang login
@riverpod
Stream<List<OrderModel>> mySellerOrders(Ref ref) {
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return ref.watch(orderRepositoryProvider).watchOrdersBySeller(user.uid);
  });
}

/// Stream tugas aktif kurir yang sedang login
@riverpod
Stream<List<OrderModel>> myCourierTasks(Ref ref) {
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return const Stream.empty();
    return ref.watch(orderRepositoryProvider).watchOrdersByCourier(user.uid);
  });
}

/// Stream orders berdasarkan status (untuk admin)
@riverpod
Stream<List<OrderModel>> ordersByStatus(Ref ref, String status) {
  return ref.watch(orderRepositoryProvider).watchOrdersByStatus(status);
}
