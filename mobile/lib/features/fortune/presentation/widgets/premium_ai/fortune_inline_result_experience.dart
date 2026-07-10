import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/fortune_type_entity.dart';
import '../../services/fortune_share_handler.dart';
import '../fortune_mystic_bar_button.dart';
import '../fortune_mystic_title_bar.dart';
import '../fortune_listen_button.dart';
import '../fortune_share_sheet.dart';
import '../fortune_type_context_header.dart';
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
  var _autoShareTried = false;

  FortuneReadingResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoShareToSocial());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _autoShareToSocial() async {
    if (_autoShareTried) return;
    _autoShareTried = true;
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;
    try {
      final shared =
          await ref.read(fortuneShareHandlerProvider).autoShareIfEnabled(result);
      if (!mounted || !shared) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CanlıFal Sosyal bölümünde paylaşıldı')),
      );
    } catch (_) {}
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
                title: result.type.title,
                onBack: widget.onNewReading ?? () => Navigator.of(context).maybePop(),
                trailing: FortuneMysticBarButton(
                  icon: Icons.ios_share_rounded,
                  onPressed: _openShareSheet,
                ),
              ),
              FortuneTypeContextHeader(type: result.type),
              Expanded(
                child: PremiumFortuneResultCanvas(
                  result: result,
                  scrollController: _scroll,
                  appBarTitle: result.type.title,
                  showTopBar: false,
                  showHero: false,
                  useBackground: false,
                  header: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: FortunePremiumResultCard(result: result),
                  ),
                  listenButton: FortuneListenButton(result: result),
                  footer: Column(
                    children: [
                      const SizedBox(height: 20),
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
