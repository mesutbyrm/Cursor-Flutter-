import 'package:flutter/material.dart';

import '../../../../core/theme/app_design.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppDesign.heroGradient,
                  boxShadow: AppDesign.glowShadow(AppDesign.accentPink),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (b) => AppDesign.heroGradient.createShader(b),
                child: const Text(
                  'Canlifal',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yükleniyor…',
                style: TextStyle(
                  color: AppDesign.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppDesign.accentPink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
