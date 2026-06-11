import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../../core/ui/premium_2026/liquid_glass.dart';
import '../../../../../core/ui/premium_2026/premium_typography.dart';
import '../../../../../core/widgets/canlifal_brand_logo.dart';

/// Giriş / kayıt — galaksi arka plan + liquid glass form kartı.
class AuthPremiumShell extends StatelessWidget {
  const AuthPremiumShell({
    super.key,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.heroLogo = false,
    this.topTitle,
    this.topSubtitle,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  final bool heroLogo;
  final String? topTitle;
  final String? topSubtitle;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxW = (mq.size.width - 40).clamp(280.0, 420.0);
    final logoSize = (mq.size.width * 0.22).clamp(72.0, 96.0);

    final glassBlur = !kIsWeb && Platform.isAndroid ? 0.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      body: CosmicGalaxyBackground(
        animate: !(!kIsWeb && Platform.isAndroid),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white.withValues(alpha: 0.85),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        showBack ? 0 : 12,
                        20,
                        mq.viewInsets.bottom + 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - mq.viewInsets.bottom,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (heroLogo)
                              Hero(
                                tag: 'auth_brand_logo',
                                child: CanlifalBrandLogo.appIcon(size: logoSize),
                              ),
                            if (topTitle != null) ...[
                              const SizedBox(height: 20),
                              Text(
                                topTitle!,
                                textAlign: TextAlign.center,
                                style: PremiumTypography.displayMedium(context),
                              ),
                            ],
                            if (topSubtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                topSubtitle!,
                                textAlign: TextAlign.center,
                                style: PremiumTypography.body(context).copyWith(
                                  color: Colors.white.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: maxW,
                              child: LiquidGlass(
                                padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
                                borderRadius: BorderRadius.circular(32),
                                blur: glassBlur,
                                elevated: true,
                                child: child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
