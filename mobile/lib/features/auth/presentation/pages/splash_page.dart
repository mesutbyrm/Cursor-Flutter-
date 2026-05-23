import 'package:flutter/material.dart';

import '../../../../core/widgets/canlifal_brand_logo.dart';

/// CanlıFal açılış — splash görseli ekrana sığdırılır (contain).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const _asset = 'assets/splash/splash_screen.png';
  static const _bg = Color(0xFF0A0618);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: DecoratedBox(
        decoration: BoxDecoration(color: _bg),
        child: SafeArea(
          child: _SplashImage(),
        ),
      ),
    );
  }
}

class _SplashImage extends StatelessWidget {
  const _SplashImage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: Image.asset(
                SplashPage._asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => CanlifalBrandLogo.horizontal(
                  height: (constraints.maxHeight * 0.22).clamp(72.0, 140.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
