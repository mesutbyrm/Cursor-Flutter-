import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/premium_2026/premium_typography.dart';
import '../../../../../core/widgets/canlifal_brand_logo.dart';

/// Android auth — blur/cam/hero yok; opak yüzey (gri overlay önlenir).
class AuthPlainShell extends StatelessWidget {
  const AuthPlainShell({
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

  static const _bg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A0E38), Color(0xFF12082A), Color(0xFF0A0618)],
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxW = (mq.size.width - 40).clamp(280.0, 420.0);
    final logoSize = (mq.size.width * 0.22).clamp(72.0, 96.0);

    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF05050D),
        // Klavye açılınca gövde küçülmesin: arka plan görseli Stack'te sabit
        // kalır (yeniden ölçeklenmez); form klavye boşluğunu kendi dolgusuyla
        // (viewInsets.bottom) yönetir.
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(gradient: _bg)),
            ),
            // Gece gökyüzü illüstrasyonu (1060×1844, kenar boşlukları kırpılmış).
            // BoxFit.cover: oranı bozmadan ekranı kaplar.
            Positioned.fill(
              child: ExcludeSemantics(
                child: Image.asset(
                  'assets/backgrounds/login-night-sky.webp',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: 1080,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Metin okunurluğu için koyu degrade bindirme.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x990A0618), Color(0xD90A0618)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white.withValues(alpha: 0.85),
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
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
                              minHeight: (constraints.maxHeight -
                                      mq.viewInsets.bottom)
                                  .clamp(0.0, double.infinity),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (heroLogo)
                                  CanlifalBrandLogo.appIcon(size: logoSize),
                                if (topTitle != null) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    topTitle!,
                                    textAlign: TextAlign.center,
                                    style: PremiumTypography.displayMedium(
                                      context,
                                    ),
                                  ),
                                ],
                                if (topSubtitle != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    topSubtitle!,
                                    textAlign: TextAlign.center,
                                    style: PremiumTypography.body(context)
                                        .copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.62,
                                          ),
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: maxW,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      color: const Color(0xFF1A1030),
                                      border: Border.all(
                                        color: const Color(0x55B84DFF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        22,
                                        26,
                                        22,
                                        28,
                                      ),
                                      child: child,
                                    ),
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
          ],
        ),
      ),
    );
  }
}
