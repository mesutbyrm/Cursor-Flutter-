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
    colors: [
      Color(0xFF1A0E38),
      Color(0xFF12082A),
      Color(0xFF0A0618),
    ],
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
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: _bg),
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
                            minHeight:
                                constraints.maxHeight - mq.viewInsets.bottom,
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
                                  style:
                                      PremiumTypography.displayMedium(context),
                                ),
                              ],
                              if (topSubtitle != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  topSubtitle!,
                                  textAlign: TextAlign.center,
                                  style: PremiumTypography.body(context)
                                      .copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.62),
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
        ),
      ),
    );
  }
}
