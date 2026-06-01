import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../../live/presentation/gifts/widgets/floating_gift_particles.dart';
import '../../../live/presentation/gifts/widgets/gift_fullscreen_overlay.dart';
import '../../../live/presentation/gifts/widgets/gift_notification_stack.dart';
import '../widgets/premium_gift_panel.dart';
import '../widgets/room_gift_panel.dart';

/// Web’e gitmeden hediye gönder — canlı yayın veya oda.
class GiftSendPage extends ConsumerStatefulWidget {
  const GiftSendPage({
    super.key,
    this.streamId,
    this.roomId,
    this.receiverName = 'Yayıncı',
  });

  final String? streamId;
  final String? roomId;
  final String receiverName;

  @override
  ConsumerState<GiftSendPage> createState() => _GiftSendPageState();
}

class _GiftSendPageState extends ConsumerState<GiftSendPage> {
  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachGifts());
  }

  void _attachGifts() {
    final streamId = widget.streamId;
    if (streamId == null || streamId.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    ref.read(liveGiftControllerProvider).attach(
          streamId: streamId,
          receiverName: widget.receiverName,
          initialCoins: user?.coinBalance,
        );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final giftCtrl = ref.watch(liveGiftControllerProvider);
    final streamId = widget.streamId ?? '';
    final roomId = widget.roomId ?? '';

    ref.listen(liveGiftControllerProvider, (_, next) {
      final e = next.activeFullscreen;
      if (e != null) _particlesKey.currentState?.burst(e.giftId);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hediye Gönder'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          if (streamId.isNotEmpty) ...[
            FloatingGiftParticles(key: _particlesKey),
            GiftFullscreenOverlay(event: giftCtrl.activeFullscreen),
            GiftNotificationStack(events: giftCtrl.notifications),
          ],
          if (streamId.isNotEmpty && user != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PremiumGiftPanel(
                controller: giftCtrl,
                streamId: streamId,
                senderName: user.displayName ?? user.username,
                senderId: user.id,
                onClose: () => Navigator.of(context).pop(),
              ),
            )
          else if (roomId.isNotEmpty)
            RoomGiftPanel(
              roomId: roomId,
              receiverName: widget.receiverName,
              onSent: () => Navigator.of(context).pop(),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Hediye göndermek için geçerli bir yayın veya oda gerekli.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
