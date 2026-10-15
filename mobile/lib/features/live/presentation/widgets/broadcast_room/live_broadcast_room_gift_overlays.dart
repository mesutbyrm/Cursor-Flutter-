import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/presentation/engine/gift_engine_overlay.dart';
import '../../../../gifts/presentation/engine/gift_engine_seat_effects_overlay.dart';
import '../../../../gifts/presentation/engine/gift_feed_panel.dart';
import '../../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../providers/live_broadcast_settings_provider.dart';

/// Canlı yayın — hediye motoru + kuyruk paneli (video/chat katmanından ayrı).
class LiveBroadcastRoomGiftOverlays extends ConsumerWidget {
  const LiveBroadcastRoomGiftOverlays({
    super.key,
    required this.streamId,
    required this.activeGift,
    this.clipToVideoRegion = false,
    this.belowSeatsTopFraction,
  });

  final String streamId;
  final dynamic activeGift;

  /// PK split: yalnızca hediye kuyruk paneli konumu etkilenir (animasyon tam ekran).
  final bool clipToVideoRegion;

  /// Misafir/PK bölünmüş sahnede hediye animasyonu koltukların (üst yarı)
  /// ALTINDA, alt bölgede oynar; koltuklar, isimler ve butonlar görünür kalır.
  /// `null` → tam ekran (tek yayıncı).
  final double? belowSeatsTopFraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(liveBroadcastSettingsProvider);
    // Tek yayıncıda hediye tam ekran (sohbet/butonların altında); misafir veya
    // PK bölünmüş sahnede koltukların altındaki bölgede oynar.
    Widget giftStack({required Widget child}) => Positioned.fill(child: child);

    return Stack(
      fit: StackFit.expand,
      children: [
        giftStack(
          child: GiftEngineSeatEffectsOverlay(event: activeGift),
        ),
        _giftRegion(
          context,
          IgnorePointer(
            child: GiftEngineOverlay(
              event: activeGift,
              enabled: settings.giftsEnabled,
              stage: GiftStageContext.liveStream,
              sessionKey: streamId,
              onFinished: (id) {
                ref
                    .read(giftSessionProvider(streamId).notifier)
                    .dequeueAnimation(id);
              },
            ),
          ),
        ),
        GiftFeedPanel(
          sessionKey: streamId,
          topFraction: clipToVideoRegion ? 0.57 : 0.40,
          maxWidth: clipToVideoRegion ? 220 : 270,
        ),
      ],
    );
  }

  Widget _giftRegion(BuildContext context, Widget child) {
    final frac = belowSeatsTopFraction;
    if (frac == null) return Positioned.fill(child: child);
    final mq = MediaQuery.of(context);
    final top = mq.size.height * frac;
    final region = Size(mq.size.width, math.max(0, mq.size.height - top));
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        // Hediye motoru ekran boyutunu MediaQuery'den okur; alt bölgeye göre
        // ölçeklensin ve üst güvenli alan boşluğu tekrar eklenmesin.
        child: MediaQuery(
          data: mq.copyWith(
            size: region,
            padding: mq.padding.copyWith(top: 0),
            viewPadding: mq.viewPadding.copyWith(top: 0),
          ),
          child: child,
        ),
      ),
    );
  }
}
