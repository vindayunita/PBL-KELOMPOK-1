import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';

part 'auth_providers.g.dart';

// ── Auth state stream (used by go_router guard) ───────────────────────────────
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// ── Current user convenience provider ────────────────────────────────────────
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authStateChangesProvider).value;
}
