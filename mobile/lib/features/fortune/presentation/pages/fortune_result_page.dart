import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../services/fortune_share_handler.dart';
import '../widgets/fortune_share_sheet.dart';
import '../widgets/premium_2026/fortune_browse_carousel.dart';
import '../widgets/premium_2026/fortune_premium_result_card.dart';
import '../widgets/premium_2026/fortune_similar_section.dart';
import '../widgets/premium_2026/fortune_type_immersive_scaffold.dart';
import '../widgets/premium_ai/fortune_result_action_panel.dart';
import '../widgets/premium_ai/fortune_share_story_card.dart';
import '../widgets/premium_ai/premium_fortune_result_canvas.dart';

/// Premium AI fal sonucu — derin link / geçmiş rotası.
class FortuneResultPage extends ConsumerStatefulWidget {
  const FortuneResultPage({super.key, required this.result});

  final FortuneReadingResult result;

  @override
  ConsumerState<FortuneResultPage> createState() => _FortuneResultPageState();
}

class _FortuneResultPageState extends ConsumerState<FortuneResultPage> {
  final _scroll = ScrollController();
  final _shareCardKey = GlobalKey();
  var _manualShared = false;
  var _socialSharing = false;

  FortuneReadingResult get result => widget.result;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _shareToSocialFeed() async {
    if (_manualShared || _socialSharing) return;
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sosyal paylaşım için giriş yapın')),
        );
      }
      return;
    }
    setState(() => _socialSharing = true);
    try {
      await ref.read(fortuneShareHandlerProvider).shareToSocialFeed(result);
      if (mounted) {
        setState(() {
          _manualShared = true;
          _socialSharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falın sosyal akışta paylaşıldı ✨')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _socialSharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşım şu an yapılamadı')),
        );
      }
    }
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0118),
      body: Stack(
        children: [
          FortuneTypeImmersiveScaffold(
            type: result.type,
            child: PremiumFortuneResultCanvas(
              result: result,
              scrollController: _scroll,
              appBarTitle: 'Fal Sonucu',
              onShare: _openShareSheet,
              header: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FortunePremiumResultCard(result: result),
              ),
              footer: Column(
                children: [
                  const SizedBox(height: 20),
                  FortuneSimilarSection(currentSlug: result.type.slug),
                  const SizedBox(height: 20),
                  FortuneBrowseCarousel(excludeSlug: result.type.slug),
                  const SizedBox(height: 16),
                ],
              ),
            ),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FortuneResultActionPanel(
            result: result,
            socialSharing: _socialSharing,
            socialShared: _manualShared,
            onShare: _openShareSheet,
            onShareToSocial: _shareToSocialFeed,
            onBrowseMore: () => context.go('/fortune'),
          ),
        ),
      ),
    );
  }
}
