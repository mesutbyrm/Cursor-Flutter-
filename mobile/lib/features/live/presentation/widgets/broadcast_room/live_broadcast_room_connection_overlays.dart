import 'package:flutter/material.dart';

import '../../../../vip_gold/domain/entrance_theme.dart';
import '../premium_2026/live_vip_chat_badge.dart';
import 'live_host_away_viewer_banner.dart';
import 'live_reconnect_banner.dart';

/// Bağlantı / VIP / katılım isteği banner katmanı (video üstü).
class LiveBroadcastRoomConnectionOverlays extends StatelessWidget {
  const LiveBroadcastRoomConnectionOverlays({
    super.key,
    required this.topInset,
    required this.hasStream,
    required this.isHost,
    required this.viewerHostAwayBannerVisible,
    required this.hostAway,
    required this.phaseReconnecting,
    required this.phaseError,
    required this.viewerGraceEndsAt,
    required this.onRetryRtc,
    required this.vipBannerName,
    required this.vipBannerTheme,
    required this.onVipBannerDone,
    required this.joinRequestPending,
    required this.coHostUpgraded,
  });

  final double topInset;
  final bool hasStream;
  final bool isHost;
  final bool viewerHostAwayBannerVisible;
  final bool hostAway;
  final bool phaseReconnecting;
  final bool phaseError;
  final DateTime? viewerGraceEndsAt;
  final VoidCallback onRetryRtc;
  final String? vipBannerName;
  final EntranceTheme? vipBannerTheme;
  final VoidCallback onVipBannerDone;
  final bool joinRequestPending;
  final bool coHostUpgraded;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (hasStream &&
            viewerHostAwayBannerVisible &&
            !isHost &&
            !hostAway)
          LiveHostAwayViewerBanner(graceEndsAt: viewerGraceEndsAt),
        if (hasStream && phaseReconnecting && !hostAway)
          LiveReconnectBanner(
            message: isHost
                ? 'Bağlantı koptu — yayın yeniden bağlanıyor…'
                : 'Yayın yeniden bağlanıyor — video birazdan devam edecek',
          ),
        if (hasStream && phaseError && !isHost && !hostAway)
          LiveReconnectBanner(
            message: 'Bağlantı hatası — yayına yeniden bağlanmayı deneyin',
            onRetry: onRetryRtc,
          ),
        if (vipBannerName != null)
          Positioned(
            top: topInset + 72,
            left: 16,
            right: 16,
            child: LiveVipEntranceBanner(
              displayName: vipBannerName!,
              theme: vipBannerTheme,
              onDone: onVipBannerDone,
            ),
          ),
        if (joinRequestPending && !isHost && !coHostUpgraded)
          Positioned(
            top: topInset + 72,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Yayına katılma isteği gönderildi — yayıncı onayı bekleniyor',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
