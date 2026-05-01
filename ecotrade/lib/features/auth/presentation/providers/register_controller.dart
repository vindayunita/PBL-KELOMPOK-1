import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/auth_repository.dart';
import '../../../../features/user/data/user_repository.dart';
import '../../../../features/user/domain/models/user_model.dart';

part 'register_controller.g.dart';

@riverpod
class RegisterController extends _$RegisterController {
  @override
  FutureOr<void> build() {}

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    // ⚠️ Baca repo SEBELUM await pertama untuk menghindari
    // "Cannot use Ref after it has been disposed" saat router
    // melakukan redirect setelah auth state berubah.
    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      // 1. Buat akun di Firebase Auth
      final credential = await authRepo.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Set display name di Firebase Auth
      await authRepo.updateDisplayName(name.trim());

      // 3. Simpan dokumen user ke Firestore
      await userRepo.createUser(
        UserModel(
          uid: credential.user!.uid,
          name: name.trim(),
          email: email.trim().toLowerCase(),
          roles: const ['buyer'],
          activeRole: 'buyer',
        ),
      );

      // Registrasi selesai — router otomatis redirect via auth state stream.
      // Tidak perlu set AsyncData karena provider mungkin sudah di-dispose.
    } catch (e, st) {
      // Kalau error, tampilkan ke UI (jika provider masih hidup)
      try {
        state = AsyncValue.error(e, st);
      } catch (_) {
        // Provider sudah di-dispose sebelum kita bisa set error — abaikan.
      }
    }
  }
}
