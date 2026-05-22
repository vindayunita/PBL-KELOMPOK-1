import 'package:flutter/material.dart';

class EcoLogoHeader extends StatelessWidget {
  const EcoLogoHeader({
    super.key,
    required this.subtitle,
  });

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Logo image
        Image.asset(
          'assets/images/ecotade_logo_final.png',
          width: 90,
          height: 90,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        // App name
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Eco',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D5A27),
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Trade',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
