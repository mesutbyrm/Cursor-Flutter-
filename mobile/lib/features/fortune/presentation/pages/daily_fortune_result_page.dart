import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../social/domain/entities/share_fortune_input.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../widgets/fortune_hub_crystal_illustration.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_mystic_bar_button.dart';
import '../widgets/fortune_mystic_title_bar.dart';
import '../widgets/fortune_share_sheet.dart';

/// Günlük fal — 2. adım: sonuç ekranı (mockup).
class DailyFortuneResultPage extends ConsumerStatefulWidget {
  const DailyFortuneResultPage({super.key, required this.result});

  final FortuneReadingResult result;

  @override
  ConsumerState<DailyFortuneResultPage> createState() =>
      _DailyFortuneResultPageState();
}

class _DailyFortuneResultPageState extends ConsumerState<DailyFortuneResultPage> {
  var _autoShared = false;

  FortuneReadingResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _shareToSocialFeed());
  }

  Future<void> _shareToSocialFeed() async {
    if (_autoShared) return;
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;
    _autoShared = true;
    try {
      await ref.read(socialRepositoryProvider).shareFortuneAuto(
            ShareFortuneInput(
              fortuneSlug: result.type.slug,
              fortuneType: result.type.title,
              summary: result.summary,
              detail: result.detail,
            ),
          );
      ref.invalidate(socialNotifierProvider);
    } catch (_) {}
  }

  (String, String) _splitSummary() {
    final s = result.summary.trim();
    final semi = s.indexOf(';');
    if (semi > 0) {
      return (
        s.substring(0, semi + 1).trim(),
        s.substring(semi + 1).trim(),
      );
    }
    final dot = s.indexOf('.');
    if (dot > 0 && dot < s.length - 1) {
      return (
        s.substring(0, dot + 1).trim(),
        s.substring(dot + 1).trim(),
      );
    }
    return (s, '');
  }

  @override
  Widget build(BuildContext context) {
    final (line1, line2) = _splitSummary();
    final serif = GoogleFonts.playfairDisplay;
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            FortuneMysticTitleBar(
              title: 'Günlük Fal Sonucu',
              onBack: () => context.pop(),
              trailing: FortuneMysticBarButton(
                icon: Icons.ios_share_rounded,
                onPressed: () => showFortuneShareSheet(context, result),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.accentPurple.withValues(alpha: 0.5),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2A1548), Color(0xFF12081F)],
                        ),
                        boxShadow: AppColors.glowShadow(
                          AppColors.accentPurple,
                          blur: 18,
                        ),
                      ),
                      child: Column(
                        children: [
                          const FortuneHubCrystalIllustration(height: 140),
                          const SizedBox(height: 16),
                          Text(
                            line1,
                            textAlign: TextAlign.center,
                            style: serif(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          if (line2.isNotEmpty)
                            Text(
                              line2,
                              textAlign: TextAlign.center,
                              style: serif(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC084FC),
                                height: 1.25,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const FortuneMysticStarDivider(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentPurple.withValues(alpha: 0.35),
                        ),
                        color: const Color(0xFF1A0B2E).withValues(alpha: 0.85),
                      ),
                      child: Text(
                        result.detail,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.95),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (result.luckyNumber != null)
                          Expanded(
                            child: _LuckyStatBox(
                              label: 'Şanslı sayı',
                              value: '${result.luckyNumber}',
                              valueColor: Colors.white,
                            ),
                          ),
                        if (result.luckyNumber != null &&
                            result.luckyColor != null)
                          const SizedBox(width: 12),
                        if (result.luckyColor != null)
                          Expanded(
                            child: _LuckyStatBox(
                              label: 'Şanslı renk',
                              value: result.luckyColor!,
                              valueColor: _colorForName(result.luckyColor!),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ShareButton(
                      onPressed: () => showFortuneShareSheet(context, result),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/fortune'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: gold,
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: gold.withValues(alpha: 0.55)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Diğer fallara göz at',
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: gold.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
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

  Color _colorForName(String name) {
    return switch (name.toLowerCase()) {
      'pembe' => const Color(0xFFF472B6),
      'mor' => const Color(0xFFC084FC),
      'altın' || 'altin' => const Color(0xFFE9C46A),
      'turkuaz' => const Color(0xFF67E8F9),
      'mavi' => const Color(0xFF93C5FD),
      _ => const Color(0xFFC084FC),
    };
  }
}

class _LuckyStatBox extends StatelessWidget {
  const _LuckyStatBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.35),
        ),
        color: const Color(0xFF1A0B2E).withValues(alpha: 0.9),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.accentPurple.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
              shadows: [
                Shadow(
                  color: valueColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Paylaş',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
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
