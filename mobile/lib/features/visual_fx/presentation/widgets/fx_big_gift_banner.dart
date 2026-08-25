import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../voice_hub/presentation/theme/voice_room_tokens.dart';
import '../../domain/fx_gift_display_item.dart';
import '../../domain/fx_gift_tier.dart';
import '../providers/voice_room_gift_display_provider.dart';

/// 1000+ jeton hediye — oda üstünde tek seferlik banner.
class FxBigGiftBanner extends ConsumerWidget {
  const FxBigGiftBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fx = ref.watch(voiceRoomGiftDisplayProvider);
    if (!fx.bigGiftVisible || fx.bigGift == null) {
      return const SizedBox.shrink();
    }
    final gift = fx.bigGift!;
    final tier = FxGiftTier.fromJeton(gift.jeton);

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          MediaQuery.paddingOf(context).top + 56,
          12,
          0,
        ),
        child: _BannerCard(gift: gift, tier: tier),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.gift, required this.tier});

  final FxGiftDisplayItem gift;
  final FxGiftTier tier;

  Color get _accent => switch (tier) {
        FxGiftTier.legendary => const Color(0xFFFFD700),
        FxGiftTier.special => VoiceRoomTokens.gold,
        _ => VoiceRoomTokens.neonPink,
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accent.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                tier == FxGiftTier.legendary ? '👑' : '🔥',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bu odada',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: gift.senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _accent,
                            ),
                          ),
                          const TextSpan(text: ', '),
                          TextSpan(
                            text: gift.receiverName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(text: "'e "),
                          TextSpan(
                            text: '${gift.jeton} jeton',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _accent,
                            ),
                          ),
                          TextSpan(text: ' değerinde ${gift.giftName} gönderdi!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
