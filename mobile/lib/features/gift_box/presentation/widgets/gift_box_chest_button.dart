import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/gift_box_models.dart';
import '../providers/gift_box_providers.dart';
import '../providers/gift_box_scope_providers.dart';

/// Odada aktif bir hediye kutusu varken görünen, hoplayıp zıplayan küçük sandık.
///
/// Dokununca kutuya katılır; sunucu görevi (takip/paylaşım vb.) ve süreyi
/// doğrular, içindeki jetonu kazananlar arasında dağıtır. Aktif kutu yoksa
/// hiçbir şey çizmez.
class GiftBoxChestButton extends ConsumerStatefulWidget {
  const GiftBoxChestButton({super.key, required this.scope});

  final GiftBoxScope scope;

  @override
  ConsumerState<GiftBoxChestButton> createState() => _GiftBoxChestButtonState();
}

class _GiftBoxChestButtonState extends ConsumerState<GiftBoxChestButton> {
  Timer? _poll;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // SSE kaçarsa kutu yine de görünsün/kaybolsun.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) ref.invalidate(giftBoxSnapshotProvider(widget.scope));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _join(GiftBoxSummary box) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (box.taskType == 'share') {
        final scope = widget.scope.streamId != null ? 'stream' : 'room';
        final targetId = widget.scope.streamId ?? widget.scope.roomId ?? '';
        if (targetId.isNotEmpty) {
          await ref.read(giftBoxRepositoryProvider).recordShare({
            'scope': scope,
            'targetId': targetId,
            'channel': 'in_app',
          });
        }
      }
      final res = await ref.read(giftBoxRepositoryProvider).joinBox(box.id);
      ref.invalidate(giftBoxSnapshotProvider(widget.scope));
      final won = res['isWinner'] == true || res['success'] == true;
      final reward = res['rewardAmount'];
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            won
                ? 'Tebrikler! Ödül: ${reward ?? '—'} jeton'
                : 'Katılım kaydedildi',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(giftBoxRefreshTickProvider(widget.scope), (_, _) {});
    final box = ref
        .watch(giftBoxSnapshotProvider(widget.scope))
        .valueOrNull
        ?.primaryActive;
    if (box == null) return const SizedBox.shrink();

    final joined = box.hasJoined;
    return Semantics(
      button: true,
      label:
          'Hediye sandığı, ${box.totalAmount} jeton, ${giftBoxTaskLabel(box.taskType)}',
      child: GestureDetector(
        onTap: joined || box.isOwner || _busy
            ? null
            : () => unawaited(_join(box)),
        child: Opacity(
          opacity: joined ? 0.55 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧰', style: TextStyle(fontSize: 26))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -6,
                    duration: 520.ms,
                    curve: Curves.easeInOut,
                  )
                  .scaleXY(begin: 1, end: 1.12, duration: 520.ms),
              Text(
                '${box.totalAmount}',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFE082),
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
