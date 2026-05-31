import 'package:flutter/material.dart';

import '../../../../core/widgets/canlifal_brand_logo.dart';

/// CanlıFal açılış — görsel tam ekrana sığdırılır (contain, kesilmeden).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const _asset = 'assets/splash/splash_screen.png';
  static const _bg = Color(0xFF0A0618);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: _SplashImage(),
    );
  }
}

class _SplashImage extends StatelessWidget {
  const _SplashImage();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ColoredBox(
      color: SplashPage._bg,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: Image.asset(
            SplashPage._asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => CanlifalBrandLogo.horizontal(
              height: (size.height * 0.22).clamp(72.0, 140.0),
            ),
          ),
        ),
      ),
    );
  }
}
