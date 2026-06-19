import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        if (!mounted) return;
        await _showSummary(context, next);
        if (!mounted) return;
        ref.read(psychicSessionEndedProvider.notifier).state = null;
        _showing = false;
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
    final lines = <String>[
      if (event.message != null && event.message!.trim().isNotEmpty)
        event.message!.trim(),
      if (duration != null && duration > 0) 'Süre: $duration dk',
      if (jeton != null && jeton > 0) 'Harcanan jeton: $jeton',
    ];
    final body = lines.isEmpty
        ? 'Canlı fal seansınız sona erdi.'
        : lines.join('\n');

    final review = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1028),
        title: const Text(
          'Seans tamamlandı',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(body),
        actions: [
          if (event.promptReview &&
              event.tellerId != null &&
              event.tellerId!.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Değerlendir'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    if (!mounted || review != true) return;
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
