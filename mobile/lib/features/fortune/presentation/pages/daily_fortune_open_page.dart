import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../services/fortune_reading_coordinator.dart';
import '../widgets/fortune_mystic_bar_button.dart';
import '../widgets/fortune_mystic_title_bar.dart';
import '../widgets/premium_2026/daily_fortune_premium_hero.dart';
import '../widgets/premium_2026/fortune_type_immersive_scaffold.dart';
import '../widgets/premium_ai/fortune_inline_result_experience.dart';
import '../widgets/premium_ai/premium_fortune_detail_transition.dart';
import '../widgets/premium_ai/premium_fortune_open_button.dart';

/// Günlük fal — inline sonuç, tür özel arka plan.
class DailyFortuneOpenPage extends ConsumerStatefulWidget {
  const DailyFortuneOpenPage({super.key, required this.type});

  final FortuneTypeEntity type;

  @override
  ConsumerState<DailyFortuneOpenPage> createState() =>
      _DailyFortuneOpenPageState();
}

class _DailyFortuneOpenPageState extends ConsumerState<DailyFortuneOpenPage> {
  var _opening = false;
  final _scroll = ScrollController();
  final _scrollParallax = ScrollParallaxNotifier();
  FortuneReadingResult? _inlineResult;

  FortuneTypeEntity get type => widget.type;

  @override
  void initState() {
    super.initState();
    _scrollParallax.bind(_scroll);
  }

  @override
  void dispose() {
    _scrollParallax.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openFortune() {
    return runPremiumFortuneOpenTransition(
      context: context,
      type: type,
      onOpen: () async {
        if (_opening) return;
        setState(() => _opening = true);
        final result = await FortuneReadingCoordinator.openReading(
          context: context,
          ref: ref,
          type: type,
          stayOnPage: true,
        );
        if (!mounted) return;
        setState(() {
          _opening = false;
          _inlineResult = result;
        });
      },
    );
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
    if (_inlineResult != null) {
      return FortuneInlineResultExperience(
        result: _inlineResult!,
        onNewReading: () => setState(() => _inlineResult = null),
        onOpenType: (t) => context.pushReplacement('/fortune/${t.slug}'),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FortuneTypeImmersiveScaffold(
        type: type,
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
                controller: _scroll,
                physics: PremiumMotion.listPhysics,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    DailyFortunePremiumHero(
                      height: 300,
                      scrollParallax: _scrollParallax,
                    ),
                    const SizedBox(height: 28),
                    PremiumFortuneOpenButton(
                      accent: AppThemeColors.accentPurple,
                      enabled: !_opening,
                      onPressed: _openFortune,
                    ),
                    if (_opening) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(
                        color: AppThemeColors.accentPurple,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kozmik enerji okunuyor…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
