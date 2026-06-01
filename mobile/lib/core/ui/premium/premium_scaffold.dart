import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Ortak sayfa iskeleti — gradient arka plan, güvenli alan, düşük nesting.
class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = false,
    this.showGlow = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showGlow) const _PremiumBackgroundGlow(),
            SafeArea(
              top: appBar != null,
              bottom: bottomNavigationBar == null,
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBackgroundGlow extends StatelessWidget {
  const _PremiumBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.9),
          radius: 1.4,
          colors: [AppColors.bgPurpleGlow, AppColors.background],
          stops: [0, 0.55],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(1.1, 0.2),
            radius: 1.1,
            colors: [Color(0x401A3A5E), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
