import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_options.dart';
import 'core/router/app_router.dart';

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
    const Color primary    = Color(0xFF4A90E2);
    const Color secondary  = Color(0xFF2D5A27);
    const Color tertiary   = Color(0xFF76C893);
    const Color neutral    = Color(0xFFF8F9FA);

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
    );
  }
}
