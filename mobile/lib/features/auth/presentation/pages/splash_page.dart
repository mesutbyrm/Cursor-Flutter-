import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../core/widgets/canlifal_brand_logo.dart';
import '../widgets/premium_auth_2026/auth_premium_loading.dart';

/// Premium 2026 açılış — galaksi, neon glow, logo pulse, parçacıklar.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: PremiumMotion.easeOut);
    _pulse = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutCubic),
    );

    _fadeCtrl.forward();
    Future<void>.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      context.go('/login');
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final logoSize = (mq.size.width * 0.38).clamp(120.0, 168.0);

    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      body: CosmicGalaxyBackground(
        showVignette: false,
        animate: !(!kIsWeb && Platform.isAndroid),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: mq.size.height * 0.18,
                  child: _logoGlow(logoSize),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulse,
                      child: Hero(
                        tag: 'auth_brand_logo',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9B4DFF)
                                    .withValues(alpha: 0.45),
                                blurRadius: 48,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF2D7A)
                                    .withValues(alpha: 0.28),
                                blurRadius: 64,
                                spreadRadius: -8,
                              ),
                            ],
                          ),
                          child: CanlifalBrandLogo.appIcon(size: logoSize),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'CanlıFal',
                      style: TextStyle(
                        fontSize: (mq.size.width * 0.07).clamp(22.0, 30.0),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: [
                          Shadow(
                            color: const Color(0xFF9B4DFF)
                                .withValues(alpha: 0.6),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sesli sohbet · Fal · Sosyal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: mq.padding.bottom + 48,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const AuthPremiumLoading(size: 40),
                      const SizedBox(height: 20),
                      const AuthPremiumLoadingBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoGlow(double size) {
    final glow = Container(
      width: size * 1.4,
      height: size * 1.4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0x55FF2D7A),
            Color(0x339B4DFF),
            Colors.transparent,
          ],
        ),
      ),
    );
    if (!kIsWeb && Platform.isAndroid) return glow;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: glow,
    );
  }
}
