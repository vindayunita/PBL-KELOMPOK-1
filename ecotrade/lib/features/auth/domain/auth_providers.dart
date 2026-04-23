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

// ── User role provider — reads 'admin' custom claim from Firebase ID token ────
// Returns 'admin' or 'buyer'. Always force-refreshes token to get latest claims.
@riverpod
Future<String> userRole(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'guest';
  // forceRefresh: true ensures we always get the latest claims from the server
  final idTokenResult = await user.getIdTokenResult(true);
  final isAdmin = idTokenResult.claims?['admin'] == true;
  return isAdmin ? 'admin' : 'buyer';
}
