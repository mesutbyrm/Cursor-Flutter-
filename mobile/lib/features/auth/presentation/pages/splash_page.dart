import 'package:flutter/material.dart';

/// CanlıFal açılış — marka splash görseli (tam ekran).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const _asset = 'assets/splash/splash_screen.png';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFF0A0618)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: AssetImage(_asset),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ],
        ),
      ),
    );
  }
}
