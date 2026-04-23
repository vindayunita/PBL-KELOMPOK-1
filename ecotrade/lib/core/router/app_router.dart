import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/buyer_dashboard/presentation/screens/buyer_dashboard_screen.dart';

part 'app_router.g.dart';

// ── Route name constants ──────────────────────────────────────────────────────
abstract class AppRoutes {
  static const login         = '/login';
  static const register      = '/register';
  static const buyerDashboard = '/dashboard';
}

// ── Router provider ───────────────────────────────────────────────────────────
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    // ── Auth redirect guard ──
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (isLoggedIn && isAuthRoute) return AppRoutes.buyerDashboard;
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      return null;
    },

    // ── Listen to auth changes for automatic redirects ──
    refreshListenable: _AuthStateListenable(ref),

    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerDashboard,
        name: 'buyerDashboard',
        builder: (context, state) => const BuyerDashboardScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}

// ── Bridges Riverpod stream → GoRouter Listenable ────────────────────────────
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}
