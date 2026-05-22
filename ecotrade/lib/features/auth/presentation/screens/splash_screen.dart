import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── App color palette (mirrors main.dart) ─────────────────────────────────────
const _kPrimary   = Color(0xFF4A90E2); // blue
const _kPrimaryDk = Color(0xFF1A4A7A); // dark blue
const _kTertiary  = Color(0xFF76C893); // light green
const _kAccent    = Color(0xFFD0E6FA); // light blue container

/// Pure UI splash screen — no routing logic, no callbacks.
/// Shown as an overlay on top of the app via main.dart's builder.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Content: fade + slide up (starts immediately)
  late final AnimationController _contentCtrl;
  late final Animation<double>   _contentFade;
  late final Animation<Offset>   _contentSlide;

  // Logo glow pulse
  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowAnim;

  // Progress bar fills over 3 s
  late final AnimationController _progressCtrl;

  // Particle dots
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    // Content fades in immediately — no delay
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _contentFade = CurvedAnimation(
        parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _contentCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _glowCtrl.dispose();
    _progressCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox.expand(
        child: Container(
          // ── Blue-toned gradient matching app primary ──────────────────────
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D2B4E), // very dark blue
                Color(0xFF1A4A7A), // dark blue (primaryContainer dark)
                Color(0xFF2E6BAA), // mid blue → primary
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // ── Floating particles ───────────────────────────────────────
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _DotParticlePainter(_particleCtrl.value),
                  size: Size.infinite,
                ),
              ),

              // ── Diagonal accent band ─────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _AccentBandPainter()),
              ),

              // ── Centered content ─────────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Glowing logo ──────────────────────────────────
                        AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (_, child) => Container(
                            width: 156,
                            height: 156,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _kPrimary.withValues(
                                      alpha: _glowAnim.value * 0.6),
                                  blurRadius: 48,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: _kTertiary.withValues(
                                      alpha: _glowAnim.value * 0.25),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          child: Container(
                            width: 156,
                            height: 156,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _kAccent.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(26),
                            child: Image.asset(
                              'assets/images/ecotade_logo_final.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── App name shimmer (blue→green gradient) ────────
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [_kAccent, Colors.white, _kTertiary],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: const Text(
                            'EcoTrade',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Tagline pill ──────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _kAccent.withValues(alpha: 0.30),
                            ),
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: const Text(
                            'Smart Waste  ·  Smart Trade',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        const SizedBox(height: 56),

                        // ── Progress bar (blue accent) ────────────────────
                        SizedBox(
                          width: 160,
                          child: AnimatedBuilder(
                            animation: _progressCtrl,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progressCtrl.value,
                                minHeight: 3,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        _kTertiary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Floating dot particles ────────────────────────────────────────────────────
class _DotParticlePainter extends CustomPainter {
  _DotParticlePainter(this.t);
  final double t;

  static final _rng = math.Random(7);
  static final _particles = List.generate(18, (i) => {
        'x':     _rng.nextDouble(),
        'y':     _rng.nextDouble(),
        'r':     3.0 + _rng.nextDouble() * 8,
        'speed': 0.08 + _rng.nextDouble() * 0.14,
        'phase': _rng.nextDouble(),
        'drift': (_rng.nextDouble() - 0.5) * 0.05,
        'blue':  _rng.nextBool(), // blue or green tinted
      });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final phase = p['phase'] as double;
      final speed = p['speed'] as double;
      final drift = p['drift'] as double;
      final r     = p['r'] as double;
      final baseX = p['x'] as double;
      final baseY = p['y'] as double;
      final isBlue = p['blue'] as bool;

      final yPos = (baseY - ((t * speed + phase) % 1.0)) * size.height;
      final xPos =
          (baseX + math.sin((t + phase) * math.pi * 2) * drift) * size.width;
      final opacity =
          (math.sin((t + phase) * math.pi) * 0.5 + 0.5) * 0.18;

      canvas.drawCircle(
        Offset(xPos, yPos),
        r * 0.5,
        Paint()
          ..color = (isBlue ? _kAccent : _kTertiary).withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_DotParticlePainter old) => old.t != t;
}

// ── Diagonal accent band ──────────────────────────────────────────────────────
class _AccentBandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          _kPrimary.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.0, size.height * 0.30)
      ..lineTo(size.width * 1.0, size.height * 0.12)
      ..lineTo(size.width * 1.0, size.height * 0.40)
      ..lineTo(size.width * 0.0, size.height * 0.58)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AccentBandPainter _) => false;
}
