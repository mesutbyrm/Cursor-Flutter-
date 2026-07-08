import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_ended_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_review_sheet.dart';

/// Push veya seans çıkışında özet diyaloğu + isteğe bağlı değerlendirme.
class PsychicSessionEndedHost extends ConsumerStatefulWidget {
  const PsychicSessionEndedHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PsychicSessionEndedHost> createState() =>
      _PsychicSessionEndedHostState();
}

class _PsychicSessionEndedHostState extends ConsumerState<PsychicSessionEndedHost> {
  var _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<PsychicSessionEndedEvent?>(psychicSessionEndedProvider, (_, next) {
      if (next == null || _showing || !mounted) return;
      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _showing = false;
          return;
        }
        try {
          if (next.navigateAfter) {
            ref.read(goRouterProvider).go('/canli-falcilar');
          }

          final rootCtx = rootNavigatorKey.currentContext;
          if (rootCtx != null && rootCtx.mounted) {
            await _showSummary(rootCtx, next);
          }
        } catch (_) {
          if (next.navigateAfter && mounted) {
            ref.read(goRouterProvider).go('/canli-falcilar');
          }
        } finally {
          if (mounted) {
            ref.read(psychicSessionEndedProvider.notifier).state = null;
          }
          _showing = false;
        }
      });
    });
    return widget.child;
  }

  Future<void> _showSummary(
    BuildContext context,
    PsychicSessionEndedEvent event,
  ) async {
    final duration = event.durationMinutes;
    final jeton = event.totalJeton;
    final tips = event.tipsJeton;
    final lines = <String>[
      if (event.message != null && event.message!.trim().isNotEmpty)
        event.message!.trim(),
      if (duration != null && duration > 0) 'Süre: $duration dk',
      if (jeton != null && jeton > 0)
        event.isTeller ? 'Seans geliri: $jeton jeton' : 'Harcanan jeton: $jeton',
      if (tips != null && tips > 0) 'Bahşiş: $tips jeton',
      if (event.isTeller && (tips ?? 0) > 0 && (jeton ?? 0) > 0)
        'Toplam kazanç: ${(jeton ?? 0) + tips!} jeton',
    ];
    final body = lines.isEmpty
        ? 'Canlı fal seansınız sona erdi.'
        : lines.join('\n');

    final review = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1028),
        title: const Text(
          'Seans tamamlandı',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(body),
        actions: [
          if (!event.isTeller && event.sessionId.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(ctx, rootNavigator: true).pop(false);
                ref.read(goRouterProvider).push(
                      '/shorts/upload?liveClipId=${Uri.encodeComponent(event.sessionId)}&sessionId=${Uri.encodeComponent(event.sessionId)}&liveClipTitle=${Uri.encodeComponent(event.tellerName ?? 'Canlı fal')}',
                    );
              },
              child: const Text('Shorts klip'),
            ),
          if (event.promptReview &&
              event.tellerId != null &&
              event.tellerId!.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
              child: const Text('Değerlendir'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    if (!context.mounted || review != true) return;
    final tellerId = event.tellerId;
    if (tellerId == null || tellerId.isEmpty) return;
    await showPsychicReviewSheet(
      context,
      sessionId: event.sessionId,
      tellerId: tellerId,
      tellerName: event.tellerName ?? 'Falcı',
    );
  }
}
