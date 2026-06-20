import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../social/domain/entities/share_fortune_input.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_share_sheet.dart';
import '../widgets/premium_ai/fortune_result_action_panel.dart';
import '../widgets/premium_ai/fortune_share_story_card.dart';
import '../widgets/premium_ai/premium_fortune_result_canvas.dart';

/// Premium AI fal sonucu — daktilo yorum, aksiyon paneli, sosyal paylaşım.
class FortuneResultPage extends ConsumerStatefulWidget {
  const FortuneResultPage({super.key, required this.result});

  final FortuneReadingResult result;

  @override
  ConsumerState<FortuneResultPage> createState() => _FortuneResultPageState();
}

class _FortuneResultPageState extends ConsumerState<FortuneResultPage> {
  final _scroll = ScrollController();
  final _readingKey = GlobalKey();
  final _shareCardKey = GlobalKey();
  var _autoShared = false;
  var _manualShared = false;
  var _socialSharing = false;

  FortuneReadingResult get result => widget.result;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _shareToSocialFeed());
  }

  Future<void> _shareToSocialFeed({bool manual = false}) async {
    if (!manual && _autoShared) return;
    if (manual && (_manualShared || _socialSharing)) return;

    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sosyal paylaşım için giriş yapın')),
        );
      }
      return;
    }

    if (manual) {
      setState(() => _socialSharing = true);
    } else {
      _autoShared = true;
    }

    try {
      await ref.read(socialRepositoryProvider).shareFortuneAuto(
            ShareFortuneInput(
              fortuneSlug: result.type.slug,
              fortuneType: result.type.title,
              summary: result.summary,
              detail: result.fullText,
              imageUrl: result.imageUrl,
              fortuneId: result.recordId,
              visualAnalysis: result.visualAnalysis,
            ),
          );
      ref.invalidate(socialNotifierProvider);
      if (manual && mounted) {
        setState(() {
          _manualShared = true;
          _socialSharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falın sosyal akışta paylaşıldı ✨')),
        );
      }
    } catch (_) {
      if (manual && mounted) {
        setState(() => _socialSharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşım şu an yapılamadı, tekrar deneyin')),
        );
      }
    }
  }

  void _scrollToReading() {
    final ctx = _readingKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _scroll.animateTo(
      180,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _shareWithStory() async {
    final me = ref.read(authControllerProvider).valueOrNull;
    final username = me?.display ?? 'Canlifal';
    await FortuneShareImageService.shareStoryImage(
      repaintKey: _shareCardKey,
      result: result,
      username: username,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.read(authControllerProvider).valueOrNull;
    final username = me?.display ?? 'Canlifal';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0118),
      body: Stack(
        children: [
          FortuneMysticBackground(
            child: PremiumFortuneResultCanvas(
              result: result,
              scrollController: _scroll,
              readingSectionKey: _readingKey,
              onShare: () => showFortuneShareSheet(
                context,
                result,
                onShareStory: _shareWithStory,
              ),
            ),
          ),
          // Story kartı ekran dışında render — PNG yakalama için
          Positioned(
            left: -4000,
            top: 0,
            child: RepaintBoundary(
              key: _shareCardKey,
              child: FortuneShareStoryCard(
                result: result,
                username: username,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.recordId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/fortune/history/${result.recordId}',
                    ),
                    icon: const Icon(Icons.history_rounded, color: Colors.white70),
                    label: const Text(
                      'Geçmişte görüntüle',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              FortuneResultActionPanel(
                result: result,
                socialSharing: _socialSharing,
                socialShared: _manualShared || _autoShared,
                onScrollToReading: _scrollToReading,
                onShare: () => showFortuneShareSheet(
                  context,
                  result,
                  onShareStory: _shareWithStory,
                ),
                onShareToSocial: () => _shareToSocialFeed(manual: true),
                onBrowseMore: () => context.go('/fortune'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
