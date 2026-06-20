import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_image_capture_config.dart';
import '../data/fortune_type_showcase.dart';
import '../services/fortune_reading_coordinator.dart';
import '../widgets/fortune_image_capture_panel.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_mystic_bar_button.dart';
import '../widgets/fortune_mystic_title_bar.dart';
import '../widgets/fortune_popular_readings_section.dart';
import '../widgets/premium_ai/premium_fortune_cover.dart';
import '../widgets/premium_ai/premium_fortune_open_button.dart';

/// Premium AI fal vitrin — tam ekran kapak, parallax, Falını Aç CTA.
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

  FortuneTypeEntity get type => widget.type;

  bool get _needsCapture => FortuneImageCaptureConfig.requiresCapture(type);

  bool get _canOpen => !_needsCapture || _images.isValidFor(type);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      setState(() => _scrollOffset = _scroll.offset);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openFortune() {
    return FortuneReadingCoordinator.openReading(
      context: context,
      ref: ref,
      type: type,
      localImages: _needsCapture ? _images : null,
    );
  }

  @override
  Widget build(BuildContext context) {
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

    void open(FortuneTypeEntity t) {
      FortuneReadingCoordinator.openReading(
        context: context,
        ref: ref,
        type: t,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            FortuneMysticTitleBar(
              title: showcase.numberedTitle,
              onBack: () => context.pop(),
              trailing: FortuneMysticBarButton(
                icon: Icons.auto_awesome,
                onPressed: _canOpen ? _openFortune : () {},
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
                    PremiumFortuneCover(
                      type: type,
                      scrollOffset: _scrollOffset,
                      height: 300,
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
                            enabled: _canOpen,
                            onPressed: _canOpen
                                ? _openFortune
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          FortuneImageCaptureConfig.isCoffee(type)
                                              ? 'Lütfen fincan içi fotoğrafını yükleyin'
                                              : 'Lütfen el fotoğrafını yükleyin',
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          if (!_canOpen)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                FortuneImageCaptureConfig.isCoffee(type)
                                    ? 'Falını açmak için fincan içi fotoğrafı zorunludur.'
                                    : 'Falını açmak için avuç içi fotoğrafı zorunludur.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: type.accent.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            'AI, kapak görselindeki sembolleri ve enerjini analiz ederek '
                            'sana özel en az 200 kelimelik yorum üretir. Her açılış benzersizdir.',
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
                        onOpenReading: open,
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
