import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/auth_repository.dart';
import '../../../../features/user/data/user_repository.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      String email = emailOrUsername.trim();

      // Jika input bukan email (tidak mengandung @), anggap sebagai username
      if (!email.contains('@')) {
        final resolvedEmail = await userRepo.getEmailByUsername(email);
        if (resolvedEmail == null) {
          throw Exception('Username tidak ditemukan. Periksa kembali username Anda.');
        }
        email = resolvedEmail;
      }

      await authRepo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email.trim()),
    );
  }
}
