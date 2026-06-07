import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/env.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_catalog.dart';
import '../services/fortune_reading_service.dart';
import '../widgets/daily_fortune_gift_illustration.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_mystic_bar_button.dart';
import '../widgets/fortune_mystic_title_bar.dart';

/// Günlük fal — 1. adım: hediye kartı + Falını Aç (mockup).
class DailyFortuneOpenPage extends StatefulWidget {
  const DailyFortuneOpenPage({super.key, required this.type});

  final FortuneTypeEntity type;

  @override
  State<DailyFortuneOpenPage> createState() => _DailyFortuneOpenPageState();
}

class _DailyFortuneOpenPageState extends State<DailyFortuneOpenPage> {
  final _service = FortuneReadingService();
  var _loading = false;

  FortuneTypeEntity get type => widget.type;

  Future<void> _openFortune() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final result = _service.generate(type);
    if (!mounted) return;
    setState(() => _loading = false);
    context.push('/fortune/${type.slug}/result', extra: result);
  }

  void _openWeb() {
    if (!Env.useNextAuth) return;
    context.push(
      CanlifalWebRoute.location(
        relativePath: '/fal/${type.slug}',
        title: type.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.playfairDisplay(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: Colors.white,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            FortuneMysticTitleBar(
              title: 'Günlük Fal',
              onBack: () => context.pop(),
              trailing: Env.useNextAuth
                  ? FortuneMysticBarButton(
                      icon: Icons.language_rounded,
                      onPressed: _openWeb,
                    )
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: PremiumMotion.listPhysics,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2A1548).withValues(alpha: 0.95),
                            const Color(0xFF12081F),
                          ],
                        ),
                        border: Border.all(
                          color: AppThemeColors.accentPurple.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeColors.accentPurple.withValues(alpha: 0.2),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const DailyFortuneGiftIllustration(height: 200),
                          const SizedBox(height: 8),
                          Text(
                            'Bugünün enerjisi ve',
                            textAlign: TextAlign.center,
                            style: bodyStyle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Color(0xFFE879F9), Color(0xFFC084FC)],
                            ).createShader(b),
                            child: Text(
                              'sürpriz mesajın',
                              textAlign: TextAlign.center,
                              style: bodyStyle.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const FortuneMysticStarDivider(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _OpenFortuneButton(
                      loading: _loading,
                      onPressed: _openFortune,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenFortuneButton extends StatelessWidget {
  const _OpenFortuneButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFF7C3AED), Color(0xFF5B21B6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        FortuneCatalog.dailyFortune.ctaLabel,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0.3,
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
