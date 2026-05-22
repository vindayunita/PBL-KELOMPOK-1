import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_options.dart';
import 'core/router/app_router.dart';
import 'features/auth/domain/auth_providers.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

      // ── Splash overlay — shown ONLY when user is NOT already logged in ──
      builder: (context, child) {
        return _SplashOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

// ── Splash overlay wrapper ────────────────────────────────────────────────────
/// Shows the splash screen on top of the app for 3 seconds,
/// but ONLY if the user is NOT already authenticated.
class _SplashOverlay extends ConsumerStatefulWidget {
  const _SplashOverlay({required this.child});
  final Widget child;

  @override
  ConsumerState<_SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends ConsumerState<_SplashOverlay> {
  static bool _sessionSplashDone = false; // never repeat within same session

  bool _visible = false;  // whether splash overlay is showing
  bool _fading  = false;  // fading out

  static const _kSplashDuration = Duration(milliseconds: 3200);
  static const _kFadeDuration   = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    // Already shown this session → skip entirely
    if (_sessionSplashDone) return;

    // Check auth state AFTER first frame (Firebase is ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateChangesProvider);

      // User already logged in → skip splash
      if (authState.value != null) {
        _sessionSplashDone = true;
        return;
      }

      // Not logged in → show splash
      setState(() => _visible = true);

      // After splash duration, fade out
      Future.delayed(_kSplashDuration, () {
        if (!mounted) return;
        setState(() => _fading = true);

        // After fade, remove overlay
        Future.delayed(_kFadeDuration, () {
          if (!mounted) return;
          setState(() => _visible = false);
          _sessionSplashDone = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
