import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/fortune_type_entity.dart';
import '../../services/fortune_share_handler.dart';
import '../fortune_mystic_bar_button.dart';
import '../fortune_mystic_title_bar.dart';
import '../fortune_share_sheet.dart';
import '../premium_2026/fortune_browse_carousel.dart';
import '../premium_2026/fortune_premium_result_card.dart';
import '../premium_2026/fortune_similar_section.dart';
import '../premium_2026/fortune_type_immersive_scaffold.dart';
import 'fortune_share_story_card.dart';
import 'premium_fortune_result_canvas.dart';

/// Aynı sayfada premium fal sonucu — yükleme sonrası inline gösterim.
class FortuneInlineResultExperience extends ConsumerStatefulWidget {
  const FortuneInlineResultExperience({
    super.key,
    required this.result,
    this.onOpenType,
    this.onNewReading,
  });

  final FortuneReadingResult result;
  final void Function(FortuneTypeEntity type)? onOpenType;
  final VoidCallback? onNewReading;

  @override
  ConsumerState<FortuneInlineResultExperience> createState() =>
      _FortuneInlineResultExperienceState();
}

class _FortuneInlineResultExperienceState
    extends ConsumerState<FortuneInlineResultExperience> {
  final _scroll = ScrollController();
  final _shareCardKey = GlobalKey();

  FortuneReadingResult get result => widget.result;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _shareWithStory() async {
    final me = ref.read(authControllerProvider).valueOrNull;
    await FortuneShareImageService.shareStoryImage(
      repaintKey: _shareCardKey,
      result: result,
      username: me?.display ?? 'Canlifal',
    );
  }

  void _openShareSheet() {
    final handler = ref.read(fortuneShareHandlerProvider);
    showFortuneShareSheet(
      context,
      result,
      options: FortuneShareOptions(
        onShareStory: _shareWithStory,
        onShareToSocialFeed: () => handler.shareToSocialFeed(result),
        onShareToProfile: () => handler.shareToProfile(result),
        onSharePublic: () => handler.sharePublic(result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.read(authControllerProvider).valueOrNull;

    return FortuneTypeImmersiveScaffold(
      type: result.type,
      child: Stack(
        children: [
          Column(
            children: [
              FortuneMysticTitleBar(
                title: 'Fal Sonucu',
                onBack: widget.onNewReading ?? () => Navigator.of(context).maybePop(),
                trailing: FortuneMysticBarButton(
                  icon: Icons.ios_share_rounded,
                  onPressed: _openShareSheet,
                ),
              ),
              Expanded(
                child: PremiumFortuneResultCanvas(
                  result: result,
                  scrollController: _scroll,
                  appBarTitle: 'Fal Sonucu',
                  showTopBar: false,
                  showHero: false,
                  useBackground: false,
                  header: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: FortunePremiumResultCard(result: result),
                  ),
                  footer: Column(
                    children: [
                      const SizedBox(height: 20),
                      FortuneSimilarSection(
                        currentSlug: result.type.slug,
                        onOpen: widget.onOpenType,
                      ),
                      const SizedBox(height: 20),
                      FortuneBrowseCarousel(
                        excludeSlug: result.type.slug,
                        onOpen: widget.onOpenType,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FilledButton.icon(
                          onPressed: _openShareSheet,
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Paylaş'),
                          style: FilledButton.styleFrom(
                            backgroundColor: result.type.accent,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: -4000,
            child: RepaintBoundary(
              key: _shareCardKey,
              child: FortuneShareStoryCard(
                result: result,
                username: me?.display ?? 'Canlifal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
