import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/user_repository.dart';
import 'models/user_model.dart';

part 'user_providers.g.dart';

@riverpod
Stream<UserModel?> currentUserDoc(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
}

@riverpod
List<String> userRoles(Ref ref) {
  return ref.watch(currentUserDocProvider).value?.roles ?? ['buyer'];
}

@riverpod
String activeRole(Ref ref) {
  return ref.watch(currentUserDocProvider).value?.activeRole ?? 'buyer';
}
