import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/payout_model.dart';
import '../data/payout_repository.dart';

part 'payout_providers.g.dart';

@riverpod
Stream<List<PayoutModel>> payoutsByRole(Ref ref, String role) {
  return ref.watch(payoutRepositoryProvider).watchPayoutsByRole(role);
}

@riverpod
Stream<List<PayoutModel>> payoutsByUser(Ref ref, String userId) {
  return ref.watch(payoutRepositoryProvider).watchPayoutsByUser(userId);
}
