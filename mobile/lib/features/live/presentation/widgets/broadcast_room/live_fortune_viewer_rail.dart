import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../providers/live_fortune_type_options_provider.dart';
import 'live_fortune_request_form.dart';

/// Canlı fal yayını — sağ şeritte sürekli «Fal İste» paneli (web parity).
class LiveFortuneViewerRail extends ConsumerWidget {
  const LiveFortuneViewerRail({
    super.key,
    required this.streamId,
    required this.balance,
    required this.onSubmit,
    this.initialFortuneType,
  });

  final String streamId;
  final int? balance;
  final Future<bool> Function({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    required int jetonCost,
  }) onSubmit;
  final String? initialFortuneType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(liveFortuneMyStatusProvider(streamId));
    final statusLabel = statusAsync.whenOrNull(
      data: (data) => _statusLabel(data),
    );

    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27FF).withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Fal İste',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          if (statusLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              statusLabel,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _openForm(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: const Text(
              'İstek gönder',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String? _statusLabel(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;
    final status = (data['status'] ?? data['requestStatus'] ?? '')
        .toString()
        .toLowerCase();
    if (status.contains('pending') || status.contains('queued')) {
      return 'Kuyrukta';
    }
    if (status.contains('review') || status.contains('active')) {
      return 'Falınız işleniyor';
    }
    if (status.contains('answered') || status.contains('complete')) {
      return 'Yanıtlandı';
    }
    if (status.contains('hold')) return 'Beklemede';
    return null;
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          left: 16,
          right: 16,
        ),
        child: LiveFortuneRequestForm(
          balance: balance,
          initialFortuneType: initialFortuneType,
          onSubmit: onSubmit,
        ),
      ),
    );
  }
}
