import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/buyer_dashboard/presentation/screens/buyer_dashboard_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/courier_dashboard/presentation/screens/courier_dashboard_screen.dart';
import '../../features/seller_dashboard/presentation/screens/seller_shell.dart';

part 'app_router.g.dart';

// ── Route name constants ──────────────────────────────────────────────────────
abstract class AppRoutes {
  static const login            = '/login';
  static const register         = '/register';
  static const buyerDashboard   = '/dashboard';
  static const adminDashboard   = '/admin';
  static const courierDashboard = '/courier';
  static const sellerDashboard  = '/seller';
}

// ── Router provider ───────────────────────────────────────────────────────────
@riverpod
GoRouter appRouter(Ref ref) {
  final authState  = ref.watch(authStateChangesProvider);
  // Watch role as AsyncValue — data available once token is fetched
  final roleAsync  = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    // ── Role-based auth redirect guard ──
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Not logged in → send to login
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      if (isLoggedIn && isAuthRoute) {
        // Wait until role is resolved before redirecting
        return roleAsync.when(
          data: (role) =>
              role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.buyerDashboard,
          loading: () => null, // stay until token resolves
          error: (_, __) => AppRoutes.buyerDashboard,
        );
      }

      // Guard /admin — only admin role may access it
      if (state.matchedLocation == AppRoutes.adminDashboard) {
        return roleAsync.when(
          data: (role) => role == 'admin' ? null : AppRoutes.buyerDashboard,
          loading: () => null,
          error: (_, __) => AppRoutes.buyerDashboard,
        );
      }

      return null;
    },

    // ── Listen to auth + role changes for automatic redirects ──
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
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.courierDashboard,
        name: 'courierDashboard',
        builder: (context, state) {
          // sementara hardcode dulu (nanti ambil dari user)
          return const CourierDashboardScreen(
            courierId: 'courier_1',
            courierName: 'Kurir Test',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.sellerDashboard,
        name: 'sellerDashboard',
        builder: (context, state) => const SellerShell(),
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
