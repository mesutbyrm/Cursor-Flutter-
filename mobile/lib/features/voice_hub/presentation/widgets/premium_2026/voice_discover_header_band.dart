import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/wallet_navigation.dart';
import '../../../../../core/providers/auth_selectors.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';
import '../../../../inbox/presentation/inbox_routes.dart';
import '../../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/features/vip_gold/presentation/theme/vip_gold_tokens.dart';
import '../../sheets/voice_room_ranking_sheet.dart';
import 'voice_discover_2026.dart';

/// Keşfet üst bar — jeton / inbox / auth güncellemeleri liste gövdesini rebuild etmez.
class VoiceDiscoverHeaderBand extends ConsumerWidget {
  const VoiceDiscoverHeaderBand({
    super.key,
    required this.horizontalPad,
  });

  final double horizontalPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinBalance = ref.watch(coinBalanceProvider.select((v) => v)) ??
        ref.watch(currentUserCoinBalanceProvider.select((v) => v));
    final name = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.display ?? 'Misafir'),
    );
    final avatar = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.avatarUrl),
    );
    final inboxUnread = ref.watch(inboxUnreadCountProvider);

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad - 4, 10),
        decoration: BoxDecoration(
          color: DiscoverPremiumVisual.glassFill,
          border: Border(
            bottom: BorderSide(color: DiscoverPremiumVisual.glassBorder),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? canlifalImageProvider(avatar)
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        )
                      : null,
                ),
                Positioned(
                  bottom: -4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: VipGoldTokens.goldLuxury,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, $name 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    'Sesli sohbet keşfet',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => openJetonStore(context, ref: ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: VipGoldTokens.goldMid.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 16,
                      color: VipGoldTokens.goldMid,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${VoiceLiveHeader2026Format.count(coinBalance ?? 0)} +',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => showVoiceRoomRankingSheet(context, ref),
              tooltip: 'Oda sıralaması',
              icon: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFD54F),
              ),
            ),
            IconButton(
              onPressed: () => InboxRoutes.open(context),
              icon: Badge(
                isLabelVisible: inboxUnread > 0,
                label: Text('$inboxUnread'),
                child: const Icon(Icons.inbox_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
