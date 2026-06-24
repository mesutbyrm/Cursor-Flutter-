import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_image_capture_config.dart';
import '../data/fortune_type_showcase.dart';
import '../services/fortune_reading_coordinator.dart';
import '../widgets/fortune_image_capture_panel.dart';
import '../widgets/fortune_mystic_bar_button.dart';
import '../widgets/fortune_mystic_title_bar.dart';
import '../widgets/fortune_popular_readings_section.dart';
import '../widgets/premium_2026/cinematic_fortune_hero.dart';
import '../widgets/premium_2026/fortune_type_immersive_scaffold.dart';
import '../widgets/premium_ai/fortune_inline_result_experience.dart';
import '../widgets/premium_ai/premium_fortune_detail_transition.dart';
import '../widgets/premium_ai/premium_fortune_open_button.dart';

/// Premium AI fal vitrin — tür özel arka plan, inline fal sonucu.
class FortuneTypeIntroPage extends ConsumerStatefulWidget {
  const FortuneTypeIntroPage({super.key, required this.type});

  final FortuneTypeEntity type;

  @override
  ConsumerState<FortuneTypeIntroPage> createState() =>
      _FortuneTypeIntroPageState();
}

class _FortuneTypeIntroPageState extends ConsumerState<FortuneTypeIntroPage> {
  FortuneLocalImageInput _images = const FortuneLocalImageInput();
  final _scroll = ScrollController();
  double _scrollOffset = 0;
  FortuneReadingResult? _inlineResult;
  var _opening = false;

  FortuneTypeEntity get type => widget.type;

  bool get _needsCapture => FortuneImageCaptureConfig.requiresCapture(type);

  bool get _canOpen => !_needsCapture || _images.isValidFor(type);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _scrollOffset = _scroll.offset));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _resetReading() => setState(() => _inlineResult = null);

  void _openType(FortuneTypeEntity t) {
    if (t.slug == type.slug) {
      _resetReading();
      return;
    }
    context.pushReplacement('/fortune/${t.slug}');
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
          localImages: _needsCapture ? _images : null,
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

  @override
  Widget build(BuildContext context) {
    if (_inlineResult != null) {
      return FortuneInlineResultExperience(
        result: _inlineResult!,
        onOpenType: _openType,
        onNewReading: _resetReading,
      );
    }

    final showcase = FortuneTypeShowcase.forSlug(type.slug);
    if (showcase == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Geri'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FortuneTypeImmersiveScaffold(
        type: type,
        child: Column(
          children: [
            FortuneMysticTitleBar(
              title: showcase.numberedTitle,
              onBack: () => context.pop(),
              trailing: FortuneMysticBarButton(
                icon: Icons.auto_awesome,
                onPressed: _canOpen && !_opening ? _openFortune : () {},
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                physics: PremiumMotion.listPhysics,
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CinematicFortuneHero(
                      type: type,
                      scrollOffset: _scrollOffset,
                      height: 320,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_needsCapture) ...[
                            FortuneImageCapturePanel(
                              type: type,
                              initial: _images,
                              onChanged: (v) => setState(() => _images = v),
                            ),
                            const SizedBox(height: 16),
                          ],
                          PremiumFortuneOpenButton(
                            accent: type.accent,
                            enabled: _canOpen && !_opening,
                            onPressed: _canOpen ? _openFortune : () {},
                          ),
                          if (_opening) ...[
                            const SizedBox(height: 14),
                            LinearProgressIndicator(
                              color: type.accent,
                              backgroundColor: type.accent.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI yorumun hazırlanıyor…',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Fal açıldığında sonuç bu sayfada anında gösterilir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FortunePopularReadingsSection(
                        excludeSlug: type.slug,
                        onOpenReading: _openType,
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
}
