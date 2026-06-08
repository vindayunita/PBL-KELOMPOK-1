import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_options.dart';
import 'core/notifications/notification_repository.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'features/auth/domain/auth_providers.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

/// GlobalKey untuk Navigator — dibutuhkan oleh NotificationService
/// agar bisa melakukan navigasi saat app di background/terminated.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash visible until we explicitly remove it
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Muat variabel lingkungan dari .env (opsional — tidak crash jika file belum ada)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // File .env belum dibuat di komputer ini.
    // Salin dari .env.example dan isi API key untuk mengaktifkan fitur Maps.
    debugPrint('[EcoTrade] File .env tidak ditemukan. Fitur Maps tidak akan berfungsi.');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Remove native splash — Flutter splash takes over immediately
  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: EcoTradeApp()));
}

class EcoTradeApp extends ConsumerWidget {
  const EcoTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // ── Custom Admin Dashboard Color Palette ──
    // primary: #4a90e2 | secondary: #2d5a27 | tertiary: #76c893 | neutral: #f8f9fa
    const Color primary   = Color(0xFF4A90E2);
    const Color secondary = Color(0xFF2D5A27);
    const Color tertiary  = Color(0xFF76C893);
    const Color neutral   = Color(0xFFF8F9FA);

    return MaterialApp.router(
      title: 'EcoTrade',
      debugShowCheckedModeBanner: false,

      // ── flex_color_scheme dynamic theming ──
      theme: FlexThemeData.light(
        colors: FlexSchemeColor(
          primary: primary,
          primaryContainer: const Color(0xFFD0E6FA),
          secondary: secondary,
          secondaryContainer: const Color(0xFFB6D6B0),
          tertiary: tertiary,
          tertiaryContainer: const Color(0xFFD4F0E0),
          appBarColor: neutral,
          error: const Color(0xFFE53935),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 9,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBorderType: FlexInputBorderType.underline,
          elevatedButtonSchemeColor: SchemeColor.onPrimary,
          elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        colors: FlexSchemeColor(
          primary: primary,
          primaryContainer: const Color(0xFF1A4A7A),
          secondary: secondary,
          secondaryContainer: const Color(0xFF1A3A16),
          tertiary: tertiary,
          tertiaryContainer: const Color(0xFF2E6B48),
          appBarColor: const Color(0xFF1A1C1E),
          error: const Color(0xFFEF9A9A),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 15,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBorderType: FlexInputBorderType.underline,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,

      builder: (context, child) {
        return _SplashOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

// ── Splash overlay wrapper ────────────────────────────────────────────────────
/// Shows the splash screen on top of the app for 3.2 seconds on every
/// cold start, regardless of auth state.
class _SplashOverlay extends ConsumerStatefulWidget {
  const _SplashOverlay({required this.child});
  final Widget child;

  @override
  ConsumerState<_SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends ConsumerState<_SplashOverlay> {
  static bool _sessionSplashDone = false; // never repeat within same session

  bool _visible = true;  // show immediately — no delay
  bool _fading  = false; // fading out
  String? _prevUserId;   // guard untuk re-init hanya saat user benar-benar berubah

  static const _kSplashDuration = Duration(milliseconds: 3200);
  static const _kFadeDuration   = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    // ── Inisialisasi NotificationService saat widget pertama kali dibuat ──────
    // Menggunakan Future.microtask agar ref.read aman dipanggil setelah frame.
    Future.microtask(() {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _prevUserId = user.uid;
        final repo = ref.read(notificationRepositoryProvider);
        NotificationService.instance.initialize(
          repository:   repo,
          userId:       user.uid,
          navigatorKey: navigatorKey,
        );
      }
    });

    // Already shown this session → skip entirely
    if (_sessionSplashDone) {
      _visible = false;
      return;
    }

    // Show splash immediately, then fade out after duration
    Future.delayed(_kSplashDuration, () {
      if (!mounted) return;
      setState(() => _fading = true);

      Future.delayed(_kFadeDuration, () {
        if (!mounted) return;
        setState(() => _visible = false);
        _sessionSplashDone = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Pantau perubahan auth state di build() — tempat yang benar untuk ref.listen
    ref.listen(currentUserProvider, (_, newUser) {
      if (newUser?.uid == _prevUserId) return; // tidak ada perubahan user
      _prevUserId = newUser?.uid;
      final repo = ref.read(notificationRepositoryProvider);
      NotificationService.instance.initialize(
        repository:   repo,
        userId:       newUser?.uid,
        navigatorKey: navigatorKey,
      );
    });

    return Stack(
      children: [
        widget.child,
        if (_visible)
          AnimatedOpacity(
            opacity: _fading ? 0.0 : 1.0,
            duration: _kFadeDuration,
            child: const SplashScreen(),
          ),
      ],
    );
  }
}
