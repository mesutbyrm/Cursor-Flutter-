import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../social/domain/entities/share_fortune_input.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_share_sheet.dart';
import '../widgets/premium_ai/premium_fortune_result_canvas.dart';

/// Premium AI fal sonucu — görsel üzerinde bölümlü yorum + otomatik sosyal paylaşım.
class FortuneResultPage extends ConsumerStatefulWidget {
  const FortuneResultPage({super.key, required this.result});

  final FortuneReadingResult result;

  @override
  ConsumerState<FortuneResultPage> createState() => _FortuneResultPageState();
}

class _FortuneResultPageState extends ConsumerState<FortuneResultPage> {
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
              detail: result.fullText,
              imageUrl: result.imageUrl,
              fortuneId: result.recordId,
              visualAnalysis: result.visualAnalysis,
            ),
          );
      ref.invalidate(socialNotifierProvider);
    } catch (_) {
      // Üretim API henüz hazır değilse sessizce geç.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0118),
      body: FortuneMysticBackground(
        child: PremiumFortuneResultCanvas(
          result: result,
          onShare: () => showFortuneShareSheet(context, result),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
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
                    label: const Text('Geçmişte görüntüle', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              FilledButton(
                onPressed: () => context.go('/fortune'),
                style: FilledButton.styleFrom(
                  backgroundColor: result.type.accent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Diğer fallara göz at'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
