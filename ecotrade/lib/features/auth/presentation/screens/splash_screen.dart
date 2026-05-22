import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure UI splash screen — no routing logic, no callbacks.
/// Shown as an overlay on top of the app via main.dart's builder.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Content: fade + slide up
  late final AnimationController _contentCtrl;
  late final Animation<double>   _contentFade;
  late final Animation<Offset>   _contentSlide;

  // Logo glow pulse
  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowAnim;

  // Progress bar fills over 3 s
  late final AnimationController _progressCtrl;

  // Leaf particles
  late final AnimationController _leafCtrl;

  @override
  void initState() {
    super.initState();

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _contentFade = CurvedAnimation(
        parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _contentCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _leafCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _glowCtrl.dispose();
    _progressCtrl.dispose();
    _leafCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0B2818),
                Color(0xFF1A4D2E),
                Color(0xFF266640),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // ── Leaf particles ──────────────────────────────────────────
              AnimatedBuilder(
                animation: _leafCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _LeafParticlePainter(_leafCtrl.value),
                  size: Size.infinite,
                ),
              ),

              // ── Diagonal accent band ────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _AccentBandPainter()),
              ),

              // ── Centered content ────────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glowing logo
                        AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (_, child) => Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF52B788).withValues(
                                      alpha: _glowAnim.value * 0.55),
                                  blurRadius: 42,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
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

                        // App name with gradient
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [Color(0xFF95D5B2), Colors.white],
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

                        // Tagline pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            color: Colors.white.withValues(alpha: 0.07),
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

                        // Progress bar
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
                                        Color(0xFF95D5B2)),
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

// ── Leaf particles ────────────────────────────────────────────────────────────
class _LeafParticlePainter extends CustomPainter {
  _LeafParticlePainter(this.t);
  final double t;

  static final _rng = math.Random(42);
  static final _particles = List.generate(14, (i) => {
        'x':     _rng.nextDouble(),
        'y':     _rng.nextDouble(),
        'r':     6.0 + _rng.nextDouble() * 14,
        'speed': 0.12 + _rng.nextDouble() * 0.18,
        'phase': _rng.nextDouble(),
        'drift': (_rng.nextDouble() - 0.5) * 0.06,
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

      final yPos = (baseY - ((t * speed + phase) % 1.0)) * size.height;
      final xPos =
          (baseX + math.sin((t + phase) * math.pi * 2) * drift) * size.width;
      final opacity =
          (math.sin((t + phase) * math.pi) * 0.5 + 0.5) * 0.22;

      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(xPos, yPos), width: r * 0.65, height: r),
        Paint()
          ..color =
              const Color(0xFF74C69D).withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_LeafParticlePainter old) => old.t != t;
}

// ── Diagonal accent band ──────────────────────────────────────────────────────
class _AccentBandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.0, size.height * 0.35)
      ..lineTo(size.width * 1.0, size.height * 0.15)
      ..lineTo(size.width * 1.0, size.height * 0.42)
      ..lineTo(size.width * 0.0, size.height * 0.62)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AccentBandPainter _) => false;
}
